-- tests/test_score_moyen_heures_jour.sql
--
-- TEST PERSONNALISE
--
-- Ce test verifie que le score mensuel reste calcule sur les heures de jour.
--
-- Pourquoi il existe
-- ------------------
-- fct_conditions_horaires force score_surf a 0 la nuit. Si quelqu'un remet un
-- jour un simple avg(score_surf) dans le mart, les dix zeros nocturnes
-- reviennent dans la moyenne et le score chute d'environ 40 % -- sans qu'une
-- seule requete echoue. Le tableau de bord affichera 2,4/10 au lieu de 4,2/10,
-- et rien ne le signalera.
--
-- C'est une panne silencieuse : le chiffre reste plausible, il est seulement
-- faux. Ce test est la pour qu'il ne le soit pas deux fois.
--
-- La regle
-- --------
-- Le score_moyen du mart doit egaler, a 0,05 pres, la moyenne recalculee
-- directement depuis la table de faits sur les seules heures de jour. La
-- tolerance absorbe l'arrondi a une decimale applique dans le mart.
--
-- Comment lire ce test : dbt considere qu'un test REUSSIT quand la requete
-- ne renvoie AUCUNE ligne.

with attendu as (

    select
        mois,
        avg(score_surf) as score_recalcule
    from {{ ref('fct_conditions_horaires') }}
    where heure between 6 and 19
    group by mois

)

select
    m.mois,
    m.score_moyen,
    round(a.score_recalcule, 1) as score_recalcule,
    'Le score mensuel ne correspond plus aux seules heures de jour' as message
from {{ ref('mart_saisonnalite_mensuelle') }} as m
join attendu as a using (mois)
where abs(m.score_moyen - a.score_recalcule) > 0.05
