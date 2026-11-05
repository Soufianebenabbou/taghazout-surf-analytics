-- tests/test_score_surf_dans_bareme.sql
--
-- TEST PERSONNALISE
--
-- Les trois scores sont annonces sur 10 : dans le tableau de bord, dans la
-- documentation, et dans la tete de celui qui les lit. Cette promesse n'est
-- garantie par rien dans le SQL -- elle resulte de sommes de bornes ecrites
-- a la main dans la macro scores_par_niveau (4+3+3, 5+3+2, 5+3+2).
--
-- Le jour ou un palier est ajoute a l'un des barèmes, le score pourra
-- depasser 10 sans qu'aucune requete n'echoue. Le tableau de bord affichera
-- simplement 11 sur 10.
--
-- Les trois barèmes doivent aussi rester comparables entre eux : c'est tout
-- l'interet de les tracer sur un meme graphique. Un barème sur 12 face a
-- deux barèmes sur 10 rendrait la comparaison fausse sans la rendre visible.
--
-- Ce test porte sur les deux tables notees a la fois : historique et
-- previsions doivent rester alignees.
--
-- Comment lire ce test : dbt considere qu'un test REUSSIT quand la requete
-- ne renvoie AUCUNE ligne.

with scores as (

    select 'fct_conditions_horaires' as modele, 'intermediaire' as niveau,
           score_surf as valeur
    from {{ ref('fct_conditions_horaires') }}
    union all
    select 'fct_conditions_horaires', 'debutant', score_debutant
    from {{ ref('fct_conditions_horaires') }}
    union all
    select 'fct_conditions_horaires', 'confirme', score_confirme
    from {{ ref('fct_conditions_horaires') }}

    union all

    select 'mart_previsions_notees', 'intermediaire', score_surf
    from {{ ref('mart_previsions_notees') }}
    union all
    select 'mart_previsions_notees', 'debutant', score_debutant
    from {{ ref('mart_previsions_notees') }}
    union all
    select 'mart_previsions_notees', 'confirme', score_confirme
    from {{ ref('mart_previsions_notees') }}

)

select
    modele,
    niveau,
    valeur,
    'Score hors du bareme annonce de 0 a 10' as message
from scores
where valeur < 0 or valeur > 10
