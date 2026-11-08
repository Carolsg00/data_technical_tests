
{{ config(materialized='view') }}

SELECT
    TRY_CAST(visit_id AS INTEGER) AS visit_id,
    TRY_CAST(intervention_point_id AS INTEGER) AS intervention_point_id,
    TRY_CAST(route_id AS INTEGER) AS route_id,
    TRY_CAST(campaign_id AS INTEGER) AS campaign_id,
    TRY_CAST(visit_date AS DATE) AS visit_date,
    NULLIF(UPPER(TRIM(visit_status)), '') AS visit_status,
    TRY_CAST(created_at AS TIMESTAMP) AS created_at,
    TRY_CAST(updated_at AS TIMESTAMP) AS updated_at

FROM {{ source('raw', 'raw_visits') }}
