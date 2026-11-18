-- tests/test_decomposition_egale_score.sql
--
-- TEST PERSONNALISE
--
-- Le tableau de bord affiche le score mensuel sous forme de barre empilee :
-- taille en bas, periode au milieu, vent en haut. La hauteur totale de la
-- barre DOIT etre le score moyen du mois, sinon la page affiche deux
-- chiffres differents pour la meme chose.
--
-- Ce test protege cette egalite :
--     points_taille_moyen + points_periode_moyen + points_vent_moyen
--     = score_moyen
--
-- Ce qu'il attraperait
-- --------------------
-- Un oubli du filtre `est_jour` sur l'une des trois moyennes. Les points ne
-- sont PAS forces a zero la nuit, contrairement a score_surf : moyenner les
-- trois sur 24 heures donnerait une somme plus haute que le score, et la
-- barre empilee depasserait silencieusement la courbe d'a cote.
--
-- La tolerance de 0,06 vient des arrondis : le score est arrondi a une
-- decimale, les trois parts a deux. L'ecart maximal legitime est donc de
-- 0,05 pour le score plus 0,015 pour les parts.
--
-- Comment lire ce test : dbt considere qu'un test REUSSIT quand la requete
-- ne renvoie AUCUNE ligne.

select
    mois,
    nom_mois,
    score_moyen,
    points_taille_moyen + points_periode_moyen + points_vent_moyen as somme_des_parts,
    abs(
        (points_taille_moyen + points_periode_moyen + points_vent_moyen)
        - score_moyen
    ) as ecart

from {{ ref('mart_saisonnalite_mensuelle') }}

where abs(
          (points_taille_moyen + points_periode_moyen + points_vent_moyen)
          - score_moyen
      ) > 0.06
