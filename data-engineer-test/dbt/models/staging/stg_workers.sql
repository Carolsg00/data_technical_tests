
{{ config(materialized='view') }}

SELECT
    TRY_CAST(employee_id AS INTEGER) AS employee_id,
    NULLIF(TRIM(employee_first_name), '') AS employee_first_name,
    TRY_CAST(employee_active_status AS BOOLEAN) AS employee_active_status,
    NULLIF(UPPER(TRIM(employee_address_province)), '') AS employee_address_province,
    NULLIF(UPPER(TRIM(employee_contract_type)), '') AS employee_contract_type,
    TRY_CAST(created_at AS DATE) AS created_at

FROM {{ source('raw', 'raw_workers') }}
