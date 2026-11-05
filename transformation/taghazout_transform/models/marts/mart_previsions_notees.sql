-- Couche gold : previsions a 7 jours, notees avec exactement les memes
-- barèmes que l'historique.
--
-- Les trois barèmes viennent de la macro scores_par_niveau, partagee avec
-- fct_conditions_horaires. Avant, ils etaient recopies ici : deux copies du
-- meme CASE, donc deux occasions de diverger. Une prevision notee autrement
-- que l'historique n'est comparable a rien.

with notes as (
    select
        *,
        {{ scores_par_niveau() }}
    from {{ ref('stg_conditions_previsions') }}
)

select
    *,

    case
        when heure between 6 and 19
            then points_taille + points_periode + points_vent
        else 0
    end as score_surf,

    case
        when heure not between 6 and 19 then 'Nuit'
        when score_debutant >= greatest(
                 score_confirme,
                 points_taille + points_periode + points_vent
             ) then 'Débutant'
        when (points_taille + points_periode + points_vent)
             >= score_confirme then 'Intermédiaire'
        else 'Confirmé'
    end as niveau_favorise

from notes
