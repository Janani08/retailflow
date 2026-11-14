
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_hk'
    )
}}

SELECT DISTINCT
    SHA2(customer_id, 256) AS customer_hk,
    customer_id AS customer_bk,
    CURRENT_TIMESTAMP() AS load_datetime,
    'UCI_ONLINE_RETAIL_II' AS record_source

FROM {{ ref('stg_sales') }} AS s

WHERE customer_id IS NOT NULL

{% if is_incremental() %}
    AND NOT EXISTS (
        SELECT 1
        FROM {{ this }} AS existing
        WHERE existing.customer_hk = SHA2(s.customer_id, 256)
    )
{% endif %}
