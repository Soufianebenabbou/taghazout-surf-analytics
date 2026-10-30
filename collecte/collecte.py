"""
Collecte Taghazout (houle + meteo) -> BigQuery (zone raw)

Ce script fait UNE seule chose : recopier ce que les API Open-Meteo renvoient
dans BigQuery, sans rien transformer. Le nettoyage viendra apres.

Deux tables, deux comportements differents, et c'est voulu :
  - historique  : WRITE_APPEND + row_hash. On ajoute a la suite, jamais on
                  n'ecrase. Une mesure passee ne change plus.
  - previsions  : REPLACE. Une prevision perimee n'a aucune valeur, la
                  remplacer est le bon comportement.

AVANT DE LANCER
---------------
Creer un fichier .env a la racine, contenant :
    GCP_PROJECT_ID=taghazout-surf
"""

import hashlib
import json
import logging
import os
from datetime import datetime, timezone

import pandas as pd
import pandas_gbq
import requests
from dotenv import load_dotenv
from google.api_core.exceptions import BadRequest, NotFound
from google.cloud import bigquery

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

load_dotenv()

# L'identifiant du projet depend du compte GCP : il vient du .env, pas du code.
PROJET_GCP = os.getenv("GCP_PROJECT_ID")
if not PROJET_GCP:
    raise RuntimeError(
        "GCP_PROJECT_ID manquant. Ajoutez-le dans un fichier .env a la racine."
    )

# Coordonnees de Taghazout (Maroc)
LATITUDE = 30.5450
LONGITUDE = -9.7100
FUSEAU = "Africa/Casablanca"

# Periode de l'historique
DATE_DEBUT = "2024-01-01"
DATE_FIN = "2025-12-31"

# Nombre de jours de prevision
JOURS_PREVISION = 7

DATASET = "taghazout_raw"

client = bigquery.Client(project=PROJET_GCP)

# Variables de houle
VARIABLES_MER = [
    "wave_height",
    "wave_period",
    "wave_direction",
    "swell_wave_height",
    "swell_wave_period",
    "sea_surface_temperature",
]

# Variables meteo
VARIABLES_METEO = [
    "temperature_2m",
    "wind_speed_10m",
    "wind_direction_10m",
    "wind_gusts_10m",
    "precipitation",
    "relative_humidity_2m",
    "dew_point_2m",
    "cloud_cover_low",
]


def appeler_api(url, variables, parametres_specifiques):
    """Appelle une API Open-Meteo et renvoie son tableau horaire."""
    parametres = {
        "latitude": LATITUDE,
        "longitude": LONGITUDE,
        "hourly": ",".join(variables),
        "timezone": FUSEAU,
        **parametres_specifiques,
    }

    reponse = requests.get(url, params=parametres, timeout=60)
    reponse.raise_for_status()

    df = pd.DataFrame(reponse.json()["hourly"])

    # Une reponse vide ne doit pas passer en silence : sans ce controle, le
    # script chargerait zero ligne en affichant un message de succes.
    if df.empty:
        raise RuntimeError(f"Reponse vide de {url}")

    logger.info(f"{len(df):>6} lignes recues de {url}")
    return df


def fusionner(mer, meteo):
    """Fusionne houle et meteo sur l'heure, et verifie qu'aucune n'est perdue.

    Un inner join ne garde que les heures presentes dans les DEUX tableaux.
    Si les deux API ne couvrent pas exactement la meme plage, des heures
    disparaissent sans aucun message. On surveille donc le volume plutot que
    de faire confiance.
    """
    fusion = mer.merge(meteo, on="time", how="inner")

    attendu = min(len(mer), len(meteo))
    if len(fusion) < attendu:
        logger.warning(
            f"{attendu - len(fusion)} heure(s) perdue(s) a la fusion : "
            f"mer={len(mer)}, meteo={len(meteo)}, fusion={len(fusion)}"
        )

    return fusion


def collecter_historique():
    """Houle (Marine) + meteo (Archive), sur la periode fixee."""
    periode = {"start_date": DATE_DEBUT, "end_date": DATE_FIN}

    mer = appeler_api(
        "https://marine-api.open-meteo.com/v1/marine", VARIABLES_MER, periode
    )
    meteo = appeler_api(
        "https://archive-api.open-meteo.com/v1/archive", VARIABLES_METEO, periode
    )

    return fusionner(mer, meteo)


def collecter_previsions():
    """Houle (Marine) + meteo (Forecast), sur les prochains jours."""
    duree = {"forecast_days": JOURS_PREVISION}

    mer = appeler_api(
        "https://marine-api.open-meteo.com/v1/marine", VARIABLES_MER, duree
    )
    meteo = appeler_api(
        "https://api.open-meteo.com/v1/forecast", VARIABLES_METEO, duree
    )

    return fusionner(mer, meteo)


def calculer_hash(ligne):
    """Empreinte unique d'une ligne.

    sort_keys=True trie les cles pour que deux lignes identiques donnent
    toujours exactement la meme chaine, donc toujours le meme hash.
    """
    texte = json.dumps(ligne, sort_keys=True, default=str, ensure_ascii=False)
    return hashlib.sha256(texte.encode("utf-8")).hexdigest()


def enrichir(df):
    """Ajoute row_hash puis inserted_at, dans cet ordre."""
    df = df.copy()

    # La colonne time arrive en texte : on la convertit en vraie date-heure.
    df["time"] = pd.to_datetime(df["time"])

    # Le hash porte sur la mesure seule, donc AVANT inserted_at. Sinon deux
    # executions a deux heures differentes donneraient deux hash differents
    # pour la meme donnee, et on ne detecterait plus les doublons.
    df["row_hash"] = df.apply(lambda ligne: calculer_hash(ligne.to_dict()), axis=1)
    df["inserted_at"] = datetime.now(timezone.utc)

    return df


def hashes_existants(nom_table):
    """Renvoie l'ensemble des row_hash deja presents dans la table.

    Un set plutot qu'une liste : la verification d'appartenance est immediate.
    """
    try:
        requete = f"SELECT DISTINCT row_hash FROM `{PROJET_GCP}.{DATASET}.{nom_table}`"
        return {ligne.row_hash for ligne in client.query(requete).result()}
    except NotFound:
        # La table n'existe pas encore : il n'y a donc aucun hash connu.
        return set()
    except BadRequest:
        # La table existe mais date d'avant l'ajout de row_hash. On ne peut
        # pas dedupliquer contre elle : il faut la reconstruire une fois.
        raise RuntimeError(
            f"La table {nom_table} n'a pas de colonne row_hash. "
            f"Supprimez-la une fois, elle sera recreee au bon schema :\n"
            f"    bq rm -f -t {PROJET_GCP}:{DATASET}.{nom_table}"
        )


def charger_historique(df):
    """N'insere que les lignes nouvelles, a la suite des precedentes."""
    deja_en_base = hashes_existants("historique")
    nouvelles = df[~df["row_hash"].isin(deja_en_base)]

    if nouvelles.empty:
        logger.info("Historique : aucune nouvelle ligne, tout est deja en base.")
        return

    pandas_gbq.to_gbq(
        nouvelles,
        destination_table=f"{DATASET}.historique",
        project_id=PROJET_GCP,
        if_exists="append",
    )
    logger.info(
        f"Historique : {len(nouvelles)} nouvelle(s) ligne(s) "
        f"sur {len(df)} collectee(s)."
    )


def charger_previsions(df):
    """Remplace integralement la table : une prevision perimee ne sert a rien."""
    pandas_gbq.to_gbq(
        df,
        destination_table=f"{DATASET}.previsions",
        project_id=PROJET_GCP,
        if_exists="replace",
    )
    logger.info(f"Previsions : {len(df)} lignes chargees.")


def main():
    """Collecte les deux jeux, puis les charge chacun selon sa regle."""
    charger_historique(enrichir(collecter_historique()))
    charger_previsions(enrichir(collecter_previsions()))
    logger.info("Collecte Taghazout terminee.")


if __name__ == "__main__":
    main()