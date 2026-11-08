
{{ config(materialized='view') }}

SELECT
    NULLIF(TRIM(ext_id), '') AS ext_id,

    NULLIF(TRIM(point_name), '') AS point_name,

    {{ normalize_text('point_name') }} AS name_normalized,

    NULLIF(TRIM(address_street), '') AS address_street,
    NULLIF(TRIM(address_number), '') AS address_number,
    NULLIF(UPPER(TRIM(address_city)), '') AS address_city,
    NULLIF(TRIM(address_zip), '') AS address_zip,

    TRY_CAST(is_active AS BOOLEAN) AS is_active

FROM {{ source('raw', 'pos_gi') }}
