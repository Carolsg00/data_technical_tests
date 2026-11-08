
{{ config(materialized='view') }}

SELECT
    TRY_CAST(route_id AS INTEGER) AS route_id,
    TRY_CAST(campaign_id AS INTEGER) AS campaign_id,
    TRY_CAST(route_start_date AS DATE) AS route_start_date,
    TRY_CAST(route_end_date AS DATE) AS route_end_date,
    NULLIF(UPPER(TRIM(route_status)), '') AS route_status,
    TRY_CAST(created_at AS TIMESTAMP) AS created_at

FROM {{ source('raw', 'raw_routes') }}
