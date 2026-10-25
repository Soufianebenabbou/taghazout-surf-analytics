-- Couche silver : on renomme en clair et on découpe la date
select
    time as horodatage,
    date(time) as jour,
    extract(hour from time) as heure,

    -- Houle
    wave_height as hauteur_vague_m,
    wave_period as periode_vague_s,
    wave_direction as direction_vague_deg,
    swell_wave_height as hauteur_houle_m,
    swell_wave_period as periode_houle_s,

    -- Météo
    temperature_2m as temperature_c,
    wind_speed_10m as vent_kmh,
    wind_direction_10m as direction_vent_deg,
    wind_gusts_10m as rafales_kmh,
    precipitation as pluie_mm

from {{ source('raw', 'historique') }}