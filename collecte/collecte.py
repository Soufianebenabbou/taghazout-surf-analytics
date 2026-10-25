# Charge les variables du fichier .env (dont le chemin de la clé BigQuery)
from dotenv import load_dotenv
load_dotenv()

# Bibliothèques : requêtes HTTP, tableaux, et chargement vers BigQuery
import requests
import pandas as pd
import pandas_gbq

# Coordonnées de Taghazout (Maroc)
LATITUDE = 30.5450
LONGITUDE = -9.7100
FUSEAU = "Africa/Casablanca"

# Période de l'historique
DATE_DEBUT = "2024-01-01"
DATE_FIN = "2025-12-31"

# Nombre de jours de prévision
JOURS_PREVISION = 7

# Destination BigQuery
PROJET_GCP = "taghazout-surf"
DATASET = "taghazout_raw"

# Variables de houle
VARIABLES_MER = [
    "wave_height",
    "wave_period",
    "wave_direction",
    "swell_wave_height",
    "swell_wave_period",
    "sea_surface_temperature",
]   

# Variables météo
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


# Appelle une API Open-Meteo et renvoie son tableau horaire
def appeler_api(url, variables, parametres_specifiques):
    parametres = {
        "latitude": LATITUDE,
        "longitude": LONGITUDE,
        "hourly": ",".join(variables),
        "timezone": FUSEAU,
        **parametres_specifiques,
    }

    reponse = requests.get(url, params=parametres, timeout=60)
    reponse.raise_for_status()

    return pd.DataFrame(reponse.json()["hourly"])


# Collecte l'historique : houle (Marine) + météo (Archive)
def collecter_historique():
    periode = {"start_date": DATE_DEBUT, "end_date": DATE_FIN}

    mer = appeler_api(
        "https://marine-api.open-meteo.com/v1/marine", VARIABLES_MER, periode
    )
    meteo = appeler_api(
        "https://archive-api.open-meteo.com/v1/archive", VARIABLES_METEO, periode
    )

    return mer.merge(meteo, on="time", how="inner")


# Collecte les prévisions : houle (Marine) + météo (Forecast)
def collecter_previsions():
    duree = {"forecast_days": JOURS_PREVISION}

    mer = appeler_api(
        "https://marine-api.open-meteo.com/v1/marine", VARIABLES_MER, duree
    )
    meteo = appeler_api(
        "https://api.open-meteo.com/v1/forecast", VARIABLES_METEO, duree
    )

    return mer.merge(meteo, on="time", how="inner")


# Envoie un tableau vers une table BigQuery, en remplaçant son contenu
def charger_dans_bigquery(df, nom_table):
    # La colonne time arrive en texte : on la convertit en vraie date-heure
    df["time"] = pd.to_datetime(df["time"])

    pandas_gbq.to_gbq(
        df,
        destination_table=f"{DATASET}.{nom_table}",
        project_id=PROJET_GCP,
        if_exists="replace",
    )
    print(f"{len(df)} lignes chargées dans {DATASET}.{nom_table}")


# Point d'entrée : on collecte puis on charge dans BigQuery
if __name__ == "__main__":
    historique = collecter_historique()
    previsions = collecter_previsions()

    charger_dans_bigquery(historique, "historique")
    charger_dans_bigquery(previsions, "previsions")