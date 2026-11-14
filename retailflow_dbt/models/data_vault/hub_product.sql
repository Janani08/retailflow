
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='product_hk'
    )
}}

SELECT DISTINCT
    SHA2(product_id, 256) AS product_hk,
    product_id AS product_bk,
    CURRENT_TIMESTAMP() AS load_datetime,
    'UCI_ONLINE_RETAIL_II' AS record_source

FROM {{ ref('stg_sales') }} AS s

WHERE product_id IS NOT NULL

{% if is_incremental() %}
    AND NOT EXISTS (
        SELECT 1
        FROM {{ this }} AS existing
        WHERE existing.product_hk = SHA2(s.product_id, 256)
    )
{% endif %}
