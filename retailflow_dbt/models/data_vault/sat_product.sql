
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='product_version_hk'
    )
}}

WITH observations AS (
    SELECT DISTINCT
        SHA2(product_id, 256) AS product_hk,
        product_description,
        invoice_date AS effective_from,
        SHA2(
            COALESCE(product_description, '<NULL>'),
            256
        ) AS hashdiff
    FROM {{ ref('stg_sales') }}
    WHERE product_id IS NOT NULL
      AND invoice_date IS NOT NULL
),

changes AS (
    SELECT
        *,
        LAG(hashdiff) OVER (
            PARTITION BY product_hk
            ORDER BY effective_from, hashdiff
        ) AS previous_hashdiff
    FROM observations
),

versions AS (
    SELECT
        SHA2(
            CONCAT_WS(
                '||',
                product_hk,
                TO_VARCHAR(effective_from),
                hashdiff
            ),
            256
        ) AS product_version_hk,
        product_hk,
        product_description,
        effective_from,
        hashdiff,
        CURRENT_TIMESTAMP() AS load_datetime,
        'UCI_ONLINE_RETAIL_II' AS record_source
    FROM changes
    WHERE previous_hashdiff IS NULL
       OR hashdiff <> previous_hashdiff
)

SELECT *
FROM versions

{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} AS existing
    WHERE existing.product_version_hk = versions.product_version_hk
)
{% endif %}
