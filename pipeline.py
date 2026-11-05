"""
Orchestration du pipeline Taghazout : collecte, puis transformation dbt.

Lancement :
    python3 pipeline.py

En production (GitHub Actions), dbt utilise la cible 'prod' et le compte de
service ; en local, la cible par defaut 'dev' et les identifiants gcloud.
"""

import logging
import os
import subprocess
import sys

sys.path.append("collecte")
from collecte import (  # noqa: E402
    charger_historique,
    charger_previsions,
    collecter_historique,
    collecter_previsions,
    enrichir,
    historique_deja_complet,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

DOSSIER_DBT = "transformation/taghazout_transform"

# Sur GitHub Actions, DBT_TARGET vaut 'prod' ; en local la variable est absente
# et dbt prend la cible par defaut du profil.
CIBLE_DBT = os.getenv("DBT_TARGET")


def etape_collecte():
    """Interroge les API et charge les deux tables dans BigQuery.

    L'historique porte sur une periode passee et figee : on ne le recollecte
    que s'il manque en base. C'est l'appel le plus lourd (17 544 lignes) et
    le seul que l'API Archive d'Open-Meteo refuse aux serveurs de GitHub
    Actions -- le sauter quand il est inutile rend l'execution quotidienne
    rapide et fiable.
    """
    logger.info("=== Collecte des donnees ===")

    if not historique_deja_complet():
        charger_historique(enrichir(collecter_historique()))

    charger_previsions(enrichir(collecter_previsions()))


def etape_transformation():
    """Construit les modeles dbt, puis lance les tests de qualite."""
    logger.info("=== Transformation dbt ===")

    cible = ["--target", CIBLE_DBT] if CIBLE_DBT else []

    # 'build' plutot que 'run' : il enchaine les modeles ET leurs tests, et
    # s'arrete au premier echec. Un modele qui ne passe pas ses tests ne doit
    # pas alimenter ceux qui en dependent.
    subprocess.run(
        ["dbt", "build", "--project-dir", DOSSIER_DBT, *cible],
        check=True,
    )


def main():
    """Enchaine les deux etapes, dans cet ordre."""
    etape_collecte()
    etape_transformation()
    logger.info("Pipeline termine.")


if __name__ == "__main__":
    main()
