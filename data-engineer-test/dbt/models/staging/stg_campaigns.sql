
{{ config(materialized='view') }}

SELECT
    TRY_CAST(campaign_id AS INTEGER) AS campaign_id,
    TRY_CAST(project_id AS INTEGER) AS project_id,
    NULLIF(TRIM(campaign_name), '') AS campaign_name,
    TRY_CAST(campaign_start_date AS DATE) AS campaign_start_date,
    TRY_CAST(campaign_end_date AS DATE) AS campaign_end_date,
    TRY_CAST(total_visits_planned AS INTEGER) AS total_visits_planned,
    TRY_CAST(created_at AS TIMESTAMP) AS created_at,
    TRY_CAST(updated_at AS TIMESTAMP) AS updated_at

FROM {{ source('raw', 'raw_campaigns') }}
