{#
    Les trois barèmes de surf de Taghazout, ecrits une seule fois.

    POURQUOI TROIS SCORES ET PAS UN
    -------------------------------
    Un score unique sur 10 fait une promesse qu'il ne peut pas tenir : il
    suppose que tous les surfeurs veulent la meme vague. C'est faux. Une houle
    de 2,5 metres est la meilleure journee de l'annee pour un confirme et une
    journee impraticable pour un debutant. Le barème historique de ce projet
    recompensait les vagues de 1,0 a 1,8 m : il decrivait donc, sans le dire,
    le point de vue d'un surfeur intermediaire.

    Trois barèmes rendent ce choix explicite au lieu de le cacher.

    CE QUI CHANGE D'UN NIVEAU A L'AUTRE
    -----------------------------------
      - la taille ideale : petite pour le debutant, grosse pour le confirme ;
      - la periode de houle : une houle longue est puissante, donc un atout
        pour le confirme et un danger pour le debutant -- le barème debutant
        recompense les houles COURTES ;
      - la tolerance au vent : un confirme passe dans du clapot, pas un
        debutant.

    Chaque barème totalise 10 points, pour que les trois courbes soient
    comparables sur un meme graphique.

    LA REGLE COMMUNE
    ----------------
    Les trois scores tombent a 0 entre 20 h et 5 h. On ne surfe pas la nuit,
    et c'est cette convention qui oblige les marts a ne moyenner que les
    heures de jour (voir mart_saisonnalite_mensuelle).

    LIMITE ASSUMEE
    --------------
    Taghazout n'est pas un spot mais une baie : Panoramas est douce, Anchor
    Point ne l'est pas. La collecte porte sur un seul point de coordonnees.
    Ces scores decrivent donc les conditions de la baie, pas le bon spot du
    jour.
#}

{% macro scores_par_niveau() %}

    -- ------------------------------------------------------------------
    -- INTERMEDIAIRE (barème historique du projet) : 4 + 3 + 3
    -- ------------------------------------------------------------------

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
    end as points_vent,

    -- ------------------------------------------------------------------
    -- DEBUTANT : 5 (taille) + 3 (vent) + 2 (houle courte)
    -- Cherche de la mousse praticable : assez de vague pour se lever,
    -- assez peu pour ne pas se faire rincer.
    -- ------------------------------------------------------------------

    case
        when heure not between 6 and 19 then 0
        else (
            case
                when hauteur_vague_m < 0.3 then 0   -- plat, rien a prendre
                when hauteur_vague_m < 0.5 then 3
                when hauteur_vague_m < 1.0 then 5   -- la zone ideale
                when hauteur_vague_m < 1.5 then 3
                when hauteur_vague_m < 2.0 then 1
                else 0                              -- trop gros, dangereux
            end
            + case
                when vent_offshore and vent_kmh < 10 then 3
                when vent_offshore and vent_kmh < 20 then 2
                when not vent_offshore and vent_kmh < 10 then 1
                else 0
            end
            + case
                when periode_houle_s < 9 then 2     -- houle courte, peu de force
                when periode_houle_s < 11 then 1
                else 0                              -- houle longue, trop puissante
            end
        )
    end as score_debutant,

    -- ------------------------------------------------------------------
    -- CONFIRME : 5 (taille) + 3 (periode) + 2 (vent)
    -- Cherche de la puissance : une grosse vague portee par une houle
    -- longue. Le vent compte moins, il sait faire avec.
    -- ------------------------------------------------------------------

    case
        when heure not between 6 and 19 then 0
        else (
            case
                when hauteur_vague_m < 1.2 then 0   -- trop petit, sans interet
                when hauteur_vague_m < 1.8 then 2
                when hauteur_vague_m < 2.5 then 4
                else 5                              -- la zone ideale
            end
            + case
                when periode_houle_s < 9 then 0
                when periode_houle_s < 11 then 1
                when periode_houle_s < 13 then 2
                else 3                              -- houle longue, puissante
            end
            + case
                when vent_offshore and vent_kmh < 25 then 2
                when vent_offshore then 1
                when not vent_offshore and vent_kmh < 15 then 1
                else 0
            end
        )
    end as score_confirme

{% endmacro %}
