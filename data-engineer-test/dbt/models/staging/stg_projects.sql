
{{ config(materialized='view') }}

SELECT
    TRY_CAST(project_id AS INTEGER) AS project_id,
    NULLIF(TRIM(client_code), '') AS client_code,
    NULLIF(TRIM(project_name), '') AS project_name,
    TRY_CAST(created_at AS TIMESTAMP) AS created_at,
    TRY_CAST(updated_at AS TIMESTAMP) AS updated_at

FROM {{ source('raw', 'raw_projects') }}
