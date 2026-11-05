-- tests/test_les_trois_niveaux_se_distinguent.sql
--
-- TEST PERSONNALISE
--
-- Ce test protege l'affirmation centrale du tableau de bord :
-- les saisons du debutant et du confirme ne coincident pas.
--
-- Ce que les donnees ont appris
-- -----------------------------
-- Taghazout tourne autour de 1,0 a 1,3 m de houle. La baie sert au debutant
-- sa taille ideale presque toute l'annee -- jusqu'a 60 % d'heures excellentes
-- en juillet -- et ne donne que rarement au confirme la combinaison grosse
-- vague + houle longue qu'il attend : 8 % en decembre, 0 % de mai a
-- septembre. Les trois niveaux ne jouent donc pas dans le meme ordre de
-- grandeur, et aucun test ne peut exiger qu'ils se partagent l'annee.
--
-- Ce qui reste vrai, et verifiable : le meilleur mois du debutant n'est pas
-- le meilleur mois du confirme. C'est exactement ce que raconte le graphique
-- a trois courbes, et c'est donc cela qu'il faut tenir.
--
-- Ce que le test attraperait
-- --------------------------
-- Une erreur de seuil dans la macro scores_par_niveau qui ferait recompenser
-- au barème confirme les memes journees qu'au barème debutant. Rien ne
-- planterait : les deux courbes se superposeraient, et le tableau de bord
-- affirmerait une opposition saisonniere qui n'existerait plus.
--
-- Comment lire ce test : dbt considere qu'un test REUSSIT quand la requete
-- ne renvoie AUCUNE ligne.

with meilleurs_mois as (

    select
        (
            select mois
            from {{ ref('mart_saisonnalite_mensuelle') }}
            order by pct_top_debutant desc, mois
            limit 1
        ) as mois_pic_debutant,
        (
            select mois
            from {{ ref('mart_saisonnalite_mensuelle') }}
            order by pct_top_confirme desc, mois
            limit 1
        ) as mois_pic_confirme,
        (
            select max(pct_top_confirme)
            from {{ ref('mart_saisonnalite_mensuelle') }}
        ) as pic_confirme

)

select
    mois_pic_debutant,
    mois_pic_confirme,
    pic_confirme,
    case
        when mois_pic_debutant = mois_pic_confirme
            then 'Debutant et confirme culminent le meme mois : les barèmes ne les distinguent plus'
        else 'Le confirme ne trouve aucune heure excellente dans l annee : son bareme est inatteignable'
    end as message
from meilleurs_mois
where mois_pic_debutant = mois_pic_confirme
   or pic_confirme = 0
