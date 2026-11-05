-- Couche gold : conditions moyennes par mois, pour le tableau de bord
--
-- UNE CONVENTION, DEUX DENOMINATEURS
-- ----------------------------------
-- fct_conditions_horaires force score_surf a 0 entre 20h et 5h : on ne surfe
-- pas la nuit. Moyenner sur les 24 heures revient donc a melanger dix zeros
-- de convention a quatorze vraies mesures, et ecrase le resultat d'environ
-- 40 %. Un score annonce a 2,4/10 au lieu de 4,2/10 ne dit pas la meme chose.
--
-- D'ou la regle appliquee ici :
--   - qualite de surf (score, % d'heures excellentes, vent, brouillard)
--     -> calculee sur les heures de jour uniquement ;
--   - conditions physiques (houle, temperatures, pluie)
--     -> calculees sur les 24 heures, elles ne dependent pas du soleil.
--
-- Le `case ... end` sans `else` renvoie null la nuit, et avg() ignore les
-- null : les nuits sortent du calcul sans sortir de la table.
--
-- heures_jour est expose a cote de heures_totales pour que le denominateur
-- de chaque pourcentage soit verifiable depuis le tableau de bord.

{% set est_jour = "heure between 6 and 19" %}

select
    mois,

    -- Libelle lisible pour le tableau de bord. On garde AUSSI `mois` : Looker
    -- Studio trie les textes par ordre alphabetique (Aout avant Janvier), donc
    -- on affiche le nom mais on trie sur le chiffre.
    {{ nom_mois('mois') }} as nom_mois,

    count(*) as heures_totales,
    countif({{ est_jour }}) as heures_jour,

    -- Qualite de surf : heures de jour uniquement
    round(avg(case when {{ est_jour }} then score_surf end), 1) as score_moyen,
    countif(score_surf >= 7) as heures_excellentes,
    round(
        countif(score_surf >= 7) / countif({{ est_jour }}) * 100, 1
    ) as pct_heures_excellentes,
    round(
        countif({{ est_jour }} and vent_offshore) / countif({{ est_jour }}) * 100, 1
    ) as pct_offshore,
    round(
        countif({{ est_jour }} and brouillard) / countif({{ est_jour }}) * 100, 1
    ) as pct_brouillard,

    -- Conditions physiques : sur les 24 heures
    round(avg(hauteur_vague_m), 2) as hauteur_moyenne_m,
    round(avg(periode_houle_s), 1) as periode_moyenne_s,
    round(avg(temperature_air_c), 1) as temperature_air_moyenne_c,
    round(avg(temperature_eau_c), 1) as temperature_eau_moyenne_c,
    round(sum(pluie_mm), 1) as pluie_cumulee_mm

from {{ ref('fct_conditions_horaires') }}
group by mois
order by mois
