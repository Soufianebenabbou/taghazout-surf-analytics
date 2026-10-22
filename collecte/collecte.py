# Bibliothèques : requêtes HTTP et manipulation de tableaux
import requests
import pandas as pd

# Coordonnées de Taghazout (Maroc)
LATITUDE = 30.5450
LONGITUDE = -9.7100
FUSEAU = "Africa/Casablanca"

# Période de l'historique
DATE_DEBUT = "2024-01-01"
DATE_FIN = "2025-12-31"

# Nombre de jours de prévision
JOURS_PREVISION = 7

# Variables de houle
VARIABLES_MER = [
    "wave_height",
    "wave_period",
    "wave_direction",
    "swell_wave_height",
    "swell_wave_period",
]

# Variables météo
VARIABLES_METEO = [
    "temperature_2m",
    "wind_speed_10m",
    "wind_direction_10m",
    "wind_gusts_10m",
    "precipitation",
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


# Point d'entrée : on collecte les deux jeux et on affiche un aperçu
if __name__ == "__main__":
    historique = collecter_historique()
    previsions = collecter_previsions()

    print("Historique :", historique.shape)
    print("Prévisions :", previsions.shape)