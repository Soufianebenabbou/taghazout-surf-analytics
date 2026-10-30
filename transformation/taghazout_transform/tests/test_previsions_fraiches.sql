-- tests/test_previsions_fraiches.sql
--
-- TEST PERSONNALISE
--
-- Ce test surveille la FRAICHEUR des previsions, pas leur contenu.
--
-- Pourquoi il existe
-- ------------------
-- La table des previsions est ecrite en REPLACE : chaque execution remplace
-- integralement la precedente. C'est le bon comportement -- une prevision
-- perimee n'a aucune valeur -- mais il a un angle mort.
--
-- Si la collecte echoue, la table n'est pas vidée : elle garde simplement
-- les previsions de la veille. Rien ne plante, rien ne manque, et le tableau
-- de bord affiche sept jours de previsions parfaitement plausibles. Decalees
-- d'un jour, mais plausibles.
--
-- C'est exactement le genre de panne qu'on ne decouvre jamais tout seul.
--
-- La regle
-- --------
-- Une prevision commence par l'heure courante. Si la plus ancienne heure de
-- la table date de plus de 24 heures, c'est que la derniere collecte n'a pas
-- abouti. Le seuil est a 24 heures, et non a quelques minutes, pour tolerer
-- un decalage de fuseau et un lancement en milieu de journee.
--
-- Comment lire ce test : dbt considere qu'un test REUSSIT quand la requete
-- ne renvoie AUCUNE ligne.

with fraicheur as (

    select
        min(horodatage) as debut_previsions,
        max(horodatage) as fin_previsions,
        timestamp_diff(
            current_timestamp(), timestamp(min(horodatage)), hour
        ) as heures_de_retard
    from {{ ref('mart_previsions_notees') }}

)

select
    debut_previsions,
    fin_previsions,
    heures_de_retard,
    'Previsions perimees : la derniere collecte a probablement echoue' as message
from fraicheur
where heures_de_retard > 24
