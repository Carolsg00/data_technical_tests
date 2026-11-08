
SELECT
    campaign_id,
    campaign_start_date,
    campaign_end_date

FROM {{ ref('stg_campaigns') }}

WHERE campaign_start_date > campaign_end_date
