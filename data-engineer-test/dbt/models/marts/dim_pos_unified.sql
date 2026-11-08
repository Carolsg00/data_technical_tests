
{{ config(materialized='table') }}

WITH omni AS (

    SELECT *
    FROM {{ ref('stg_pos_omni') }}

),

gi AS (

    SELECT *
    FROM {{ ref('stg_pos_gi') }}

),

matches_name AS (

    SELECT
        o.intervention_point_id,
        g.ext_id,
        'NAME_ZIP' AS match_rule

    FROM omni o
    INNER JOIN gi g
        ON o.name_normalized = g.name_normalized
        AND o.intervention_point_postal_code = g.address_zip

),

matches_address AS (

    SELECT
        o.intervention_point_id,
        g.ext_id,
        'ADDRESS_CITY_ZIP' AS match_rule

    FROM omni o
    INNER JOIN gi g
        ON o.intervention_point_postal_code = g.address_zip

        AND {{ normalize_text('o.intervention_point_locality') }}
            = {{ normalize_text('g.address_city') }}

        AND REPLACE(
            {{ normalize_text('o.intervention_point_address') }},
            ' Nº ',
            ' '
        ) = {{ normalize_text("g.address_street || ' ' || g.address_number") }}

    LEFT JOIN matches_name mn_o
        ON o.intervention_point_id = mn_o.intervention_point_id

    LEFT JOIN matches_name mn_g
        ON g.ext_id = mn_g.ext_id

    WHERE mn_o.intervention_point_id IS NULL
      AND mn_g.ext_id IS NULL

),

matches AS (

    SELECT * FROM matches_name

    UNION ALL

    SELECT * FROM matches_address

),

omni_rows AS (

    SELECT
        'OMNI-' || CAST(o.intervention_point_id AS VARCHAR)
            AS pos_unified_id,

        o.intervention_point_id,
        m.ext_id,

        o.intervention_point_name AS pos_name,
        o.intervention_point_postal_code AS postal_code,
        o.intervention_point_address AS address,
        o.intervention_point_locality AS locality,

        CASE
            WHEN m.ext_id IS NOT NULL THEN 'MATCHED'
            ELSE 'OMNI_ONLY'
        END AS match_status,

        COALESCE(m.match_rule, 'NO_MATCH') AS match_rule,

        CASE
            WHEN m.ext_id IS NOT NULL THEN 'BOTH'
            ELSE 'OMNI'
        END AS source_system

    FROM omni o

    LEFT JOIN matches m
        ON o.intervention_point_id = m.intervention_point_id

),

gi_only AS (

    SELECT
        'GI-' || g.ext_id AS pos_unified_id,

        CAST(NULL AS INTEGER) AS intervention_point_id,
        g.ext_id,

        g.point_name AS pos_name,
        g.address_zip AS postal_code,

        TRIM(
            COALESCE(g.address_street, '') || ' ' ||
            COALESCE(g.address_number, '')
        ) AS address,

        g.address_city AS locality,

        'GI_ONLY' AS match_status,
        'NO_MATCH' AS match_rule,
        'GI' AS source_system

    FROM gi g

    LEFT JOIN matches m
        ON g.ext_id = m.ext_id

    WHERE m.ext_id IS NULL

)

SELECT * FROM omni_rows

UNION ALL

SELECT * FROM gi_only
