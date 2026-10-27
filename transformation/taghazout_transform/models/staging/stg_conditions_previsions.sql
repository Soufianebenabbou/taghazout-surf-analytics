-- Couche silver : prévisions à 7 jours, mêmes règles que l'historique
select
    time as horodatage,
    date(time) as jour,
    extract(hour from time) as heure,

    wave_height as hauteur_vague_m,
    wave_period as periode_vague_s,
    wave_direction as direction_vague_deg,
    swell_wave_height as hauteur_houle_m,
    swell_wave_period as periode_houle_s,
    sea_surface_temperature as temperature_eau_c,

    temperature_2m as temperature_air_c,
    wind_speed_10m as vent_kmh,
    wind_direction_10m as direction_vent_deg,
    wind_gusts_10m as rafales_kmh,
    precipitation as pluie_mm,
    relative_humidity_2m as humidite_pct,
    dew_point_2m as point_rosee_c,
    cloud_cover_low as nuages_bas_pct,

    wind_direction_10m between 45 and 135 as vent_offshore,
    round(swell_wave_height / nullif(wave_height, 0), 2) as part_houle,
    relative_humidity_2m >= 95
        and (temperature_2m - dew_point_2m) <= 1.0 as brouillard

from {{ source('raw', 'previsions') }}  