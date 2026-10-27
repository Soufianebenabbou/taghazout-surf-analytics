-- Couche gold : prévisions à 7 jours, notées avec le même barème

with notes as (
    select
        *,

        case
            when hauteur_vague_m < 0.8 then 0
            when hauteur_vague_m < 1.0 then 1
            when hauteur_vague_m < 1.8 then 4
            when hauteur_vague_m < 2.5 then 3
            else 2
        end as points_taille,

        case
            when periode_houle_s < 7 then 0
            when periode_houle_s < 9 then 1
            when periode_houle_s < 11 then 2
            else 3
        end as points_periode,

        case
            when vent_offshore and vent_kmh < 10 then 3
            when vent_offshore and vent_kmh < 20 then 2
            when not vent_offshore and vent_kmh < 10 then 1
            else 0
        end as points_vent

    from {{ ref('stg_conditions_previsions') }}
)

select
    *,

    case
        when heure between 6 and 19
            then points_taille + points_periode + points_vent
        else 0
    end as score_surf

from notes