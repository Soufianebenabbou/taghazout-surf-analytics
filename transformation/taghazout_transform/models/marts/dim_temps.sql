-- Couche gold : dimension temps, une ligne par jour

with jours as (
    select distinct jour
    from {{ ref('stg_conditions_historique') }}
)

select
    jour,
    extract(year from jour) as annee,
    extract(month from jour) as mois,
    extract(day from jour) as jour_du_mois,
    extract(dayofweek from jour) as jour_semaine_num,

    -- Nom du mois en français
    case extract(month from jour)
        when 1 then 'Janvier'
        when 2 then 'Février'
        when 3 then 'Mars'
        when 4 then 'Avril'
        when 5 then 'Mai'
        when 6 then 'Juin'
        when 7 then 'Juillet'
        when 8 then 'Août'
        when 9 then 'Septembre'
        when 10 then 'Octobre'
        when 11 then 'Novembre'
        else 'Décembre'
    end as nom_mois,

    -- Saison météorologique
    case
        when extract(month from jour) in (12, 1, 2) then 'Hiver'
        when extract(month from jour) in (3, 4, 5) then 'Printemps'
        when extract(month from jour) in (6, 7, 8) then 'Été'
        else 'Automne'
    end as saison,

    -- Saison touristique vs saison de surf, d'après l'analyse
    case
        when extract(month from jour) in (11, 12, 1, 2) then 'Saison surf'
        when extract(month from jour) in (6, 7, 8, 9, 10) then 'Saison balnéaire'
        else 'Intersaison'
    end as saison_usage,

    -- Week-end ou semaine
    extract(dayofweek from jour) in (1, 7) as est_weekend

from jours