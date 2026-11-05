{#
    Traduit un numero de mois (1-12) en son nom francais.

    Pourquoi une macro plutot qu'un CASE recopie
    --------------------------------------------
    Trois modeles ont besoin de ce libelle : dim_temps, mart_saisonnalite_mensuelle
    et mart_fenetres_horaires. Recopier le CASE trois fois, c'est accepter qu'un
    jour les trois ne disent plus la meme chose.

    Ecrit ici une seule fois, appele partout :
        {{ nom_mois('mois') }} as nom_mois

    Pourquoi garder le numero a cote du nom
    ---------------------------------------
    Looker Studio trie les chaines de caracteres par ordre alphabetique : Aout
    passerait avant Janvier. Les modeles exposent donc les deux colonnes, on
    affiche le nom et on trie sur le numero.
#}

{% macro nom_mois(colonne) %}
    case {{ colonne }}
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
    end
{% endmacro %}
