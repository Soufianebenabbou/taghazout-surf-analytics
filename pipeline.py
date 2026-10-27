# Orchestration : collecte des données puis transformation dbt
import subprocess
import sys

sys.path.append("collecte")
from collecte import collecter_historique, collecter_previsions, charger_dans_bigquery


# Étape 1 : collecte des API et chargement dans BigQuery
def etape_collecte():
    print("=== Collecte des données ===")

    historique = collecter_historique()
    previsions = collecter_previsions()

    charger_dans_bigquery(historique, "historique")
    charger_dans_bigquery(previsions, "previsions")


# Étape 2 : transformation des données avec dbt
def etape_transformation():
    print("\n=== Transformation dbt ===")

    subprocess.run(
        ["dbt", "run", "--project-dir", "transformation/taghazout_transform"],
        check=True,
    )


# Point d'entrée : on exécute les deux étapes dans l'ordre
if __name__ == "__main__":
    etape_collecte()
    etape_transformation()
    print("\nPipeline terminé.")