
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='invoice_hk'
    )
}}

SELECT DISTINCT
    SHA2(invoice_id, 256) AS invoice_hk,
    invoice_id AS invoice_bk,
    CURRENT_TIMESTAMP() AS load_datetime,
    'UCI_ONLINE_RETAIL_II' AS record_source

FROM {{ ref('stg_sales') }} AS s

WHERE invoice_id IS NOT NULL

{% if is_incremental() %}
    AND NOT EXISTS (
        SELECT 1
        FROM {{ this }} AS existing
        WHERE existing.invoice_hk = SHA2(s.invoice_id, 256)
    )
{% endif %}
