-- Couche gold : conditions moyennes par mois, pour le dashboard

select
    mois,
    count(*) as heures_totales,

    -- Surf
    round(avg(hauteur_vague_m), 2) as hauteur_moyenne_m,
    round(avg(periode_houle_s), 1) as periode_moyenne_s,
    round(avg(score_surf), 1) as score_moyen,
    countif(score_surf >= 7) as heures_excellentes,
    round(countif(score_surf >= 7) / count(*) * 100, 1) as pct_heures_excellentes,
    round(countif(vent_offshore) / count(*) * 100, 1) as pct_offshore,

    -- Tourisme
    round(avg(temperature_air_c), 1) as temperature_air_moyenne_c,
    round(avg(temperature_eau_c), 1) as temperature_eau_moyenne_c,
    round(sum(pluie_mm), 1) as pluie_cumulee_mm,
    round(countif(brouillard) / count(*) * 100, 1) as pct_brouillard

from {{ ref('fct_conditions_horaires') }}
group by mois
order by mois