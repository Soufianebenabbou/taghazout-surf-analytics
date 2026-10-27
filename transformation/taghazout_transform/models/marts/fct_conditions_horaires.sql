-- Couche gold : table de faits, une ligne par heure, avec le score de surf

with base as (
    select * from {{ ref('stg_conditions_historique') }}
),

notes as (
    select
        *,

        -- Points sur la taille de vague (0 à 4)
        case
            when hauteur_vague_m < 0.8 then 0
            when hauteur_vague_m < 1.0 then 1
            when hauteur_vague_m < 1.8 then 4
            when hauteur_vague_m < 2.5 then 3
            else 2
        end as points_taille,

        -- Points sur la période de houle (0 à 3)
        case
            when periode_houle_s < 7 then 0
            when periode_houle_s < 9 then 1
            when periode_houle_s < 11 then 2
            else 3
        end as points_periode,

        -- Points sur le vent (0 à 3)
        case
            when vent_offshore and vent_kmh < 10 then 3
            when vent_offshore and vent_kmh < 20 then 2
            when not vent_offshore and vent_kmh < 10 then 1
            else 0
        end as points_vent

    from base
)

select
    *,

    -- Score total sur 10, nul en dehors des heures de jour
    case
        when heure between 6 and 19
            then points_taille + points_periode + points_vent
        else 0
    end as score_surf

from notes