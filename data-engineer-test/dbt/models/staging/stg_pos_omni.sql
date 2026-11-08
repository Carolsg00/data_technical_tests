
{{ config(materialized='view') }}

SELECT
    TRY_CAST(intervention_point_id AS INTEGER) AS intervention_point_id,
    NULLIF(TRIM(intervention_point_code), '') AS intervention_point_code,
    NULLIF(TRIM(intervention_point_name), '') AS intervention_point_name,

    {{ normalize_text('intervention_point_name') }} AS name_normalized,

    NULLIF(TRIM(intervention_point_address), '') AS intervention_point_address,
    NULLIF(TRIM(intervention_point_province), '') AS intervention_point_province,
    NULLIF(TRIM(intervention_point_locality), '') AS intervention_point_locality,
    NULLIF(TRIM(intervention_point_postal_code), '') AS intervention_point_postal_code,

    TRY_CAST(intervention_point_latitude AS DOUBLE) AS intervention_point_latitude,
    TRY_CAST(intervention_point_longitude AS DOUBLE) AS intervention_point_longitude,
    TRY_CAST(intervention_point_is_active AS BOOLEAN) AS intervention_point_is_active,

    TRY_CAST(created_at AS DATE) AS created_at,
    TRY_CAST(updated_at AS DATE) AS updated_at

FROM {{ source('raw', 'pos_omni') }}
