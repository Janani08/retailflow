
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='invoice_customer_hk'
    )
}}

SELECT DISTINCT
    SHA2(CONCAT(invoice_id, '||', customer_id), 256)
        AS invoice_customer_hk,
    SHA2(invoice_id, 256) AS invoice_hk,
    SHA2(customer_id, 256) AS customer_hk,
    CURRENT_TIMESTAMP() AS load_datetime,
    'UCI_ONLINE_RETAIL_II' AS record_source

FROM {{ ref('stg_sales') }} AS s

WHERE invoice_id IS NOT NULL
  AND customer_id IS NOT NULL

{% if is_incremental() %}
    AND NOT EXISTS (
        SELECT 1
        FROM {{ this }} AS existing
        WHERE existing.invoice_customer_hk =
            SHA2(CONCAT(s.invoice_id, '||', s.customer_id), 256)
    )
{% endif %}
