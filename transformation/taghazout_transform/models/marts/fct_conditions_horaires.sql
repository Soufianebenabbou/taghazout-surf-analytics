-- Couche gold : table de faits, une ligne par heure d'historique.
--
-- Porte les trois scores de surf (debutant, intermediaire, confirme). Les
-- barèmes sont definis une seule fois dans la macro scores_par_niveau, et
-- partages avec mart_previsions_notees : un seul endroit a modifier le jour
-- ou un seuil change.
--
-- score_surf reste le score intermediaire. C'est le score historique du
-- projet, et il est conserve sous ce nom pour ne rien casser.

with base as (
    select * from {{ ref('stg_conditions_historique') }}
),

notes as (
    select
        *,
        {{ scores_par_niveau() }}
    from base
)

select
    *,

    -- Score intermediaire, nul en dehors des heures de jour
    case
        when heure between 6 and 19
            then points_taille + points_periode + points_vent
        else 0
    end as score_surf,

    -- Le niveau pour qui la journee est la meilleure. Departège par le
    -- niveau le plus accessible quand deux scores sont a egalite : une
    -- journee egalement bonne pour tous est d'abord une journee pour tous.
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
