
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='invoice_product_hk'
    )
}}

SELECT DISTINCT
    SHA2(CONCAT(invoice_id, '||', product_id), 256)
        AS invoice_product_hk,
    SHA2(invoice_id, 256) AS invoice_hk,
    SHA2(product_id, 256) AS product_hk,
    CURRENT_TIMESTAMP() AS load_datetime,
    'UCI_ONLINE_RETAIL_II' AS record_source

FROM {{ ref('stg_sales') }} AS s

WHERE invoice_id IS NOT NULL
  AND product_id IS NOT NULL

{% if is_incremental() %}
    AND NOT EXISTS (
        SELECT 1
        FROM {{ this }} AS existing
        WHERE existing.invoice_product_hk =
            SHA2(CONCAT(s.invoice_id, '||', s.product_id), 256)
    )
{% endif %}
