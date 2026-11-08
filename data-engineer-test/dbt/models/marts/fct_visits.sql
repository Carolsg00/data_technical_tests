
{{
    config(
        materialized='incremental',
        unique_key='visit_id',
        incremental_strategy='merge'
    )
}}

WITH visits AS (

    SELECT
        visit_id,
        intervention_point_id,
        route_id,
        campaign_id,
        visit_date,
        visit_status,
        created_at,
        updated_at

    FROM {{ ref('stg_visits') }}

    {% if is_incremental() %}

    WHERE updated_at >= (
        SELECT COALESCE(
            MAX(updated_at),
            CAST('1900-01-01' AS TIMESTAMP)
        )
        FROM {{ this }}
    )

    {% endif %}

),

visits_unified AS (

    SELECT
        v.visit_id,
        v.intervention_point_id,
        d.pos_unified_id,
        v.route_id,
        v.campaign_id,
        v.visit_date,
        v.visit_status,
        v.created_at,
        v.updated_at

    FROM visits v

    LEFT JOIN {{ ref('dim_pos_unified') }} d
        ON v.intervention_point_id = d.intervention_point_id

)

SELECT *
FROM visits_unified
