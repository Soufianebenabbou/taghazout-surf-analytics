-- Couche gold : qualité des conditions selon l'heure et le mois

select
    mois,

    -- Meme principe que dans mart_saisonnalite_mensuelle : on affiche le nom,
    -- on trie sur le numero.
    {{ nom_mois('mois') }} as nom_mois,

    heure,
    round(avg(score_surf), 1) as score_moyen,
    round(countif(vent_offshore) / count(*) * 100, 1) as pct_offshore,
    round(avg(vent_kmh), 1) as vent_moyen_kmh,
    round(countif(brouillard) / count(*) * 100, 1) as pct_brouillard,
    countif(score_surf >= 7) as heures_excellentes

from {{ ref('fct_conditions_horaires') }}
group by mois, heure
order by mois, heure