-- tests/test_score_surf_dans_bareme.sql
--
-- TEST PERSONNALISE
--
-- Le score est annonce sur 10 partout : dans le tableau de bord, dans la
-- documentation, et dans la tete de celui qui le lit. Cette promesse n'est
-- garantie par rien dans le SQL : elle resulte de la somme de trois bornes
-- (4 + 3 + 3) ecrites a trois endroits differents, dans deux modeles.
--
-- Le jour ou un palier est ajoute au bareme de la taille de vague, ou qu'un
-- modele est modifie sans l'autre, le score pourra depasser 10 sans qu'aucune
-- requete n'echoue. Le tableau de bord affichera simplement 11 sur 10.
--
-- Ce test verifie la promesse, pas le calcul. Il porte sur les deux tables
-- notees a la fois : historique et previsions doivent rester alignees.
--
-- Comment lire ce test : dbt considere qu'un test REUSSIT quand la requete
-- ne renvoie AUCUNE ligne.

with scores as (

    select 'fct_conditions_horaires' as modele, score_surf
    from {{ ref('fct_conditions_horaires') }}

    union all

    select 'mart_previsions_notees' as modele, score_surf
    from {{ ref('mart_previsions_notees') }}

)

select
    modele,
    score_surf,
    'Score hors du bareme annonce de 0 a 10' as message
from scores
where score_surf < 0 or score_surf > 10
