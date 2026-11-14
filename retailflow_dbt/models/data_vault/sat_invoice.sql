
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='invoice_version_hk'
    )
}}

WITH observations AS (
    SELECT DISTINCT
        SHA2(invoice_id, 256) AS invoice_hk,
        invoice_date,
        source_year,
        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TO_VARCHAR(invoice_date), '<NULL>'),
                COALESCE(source_year, '<NULL>')
            ),
            256
        ) AS hashdiff
    FROM {{ ref('stg_sales') }}
    WHERE invoice_id IS NOT NULL
),

changes AS (
    SELECT
        *,
        LAG(hashdiff) OVER (
            PARTITION BY invoice_hk
            ORDER BY invoice_date NULLS LAST, hashdiff
        ) AS previous_hashdiff
    FROM observations
),

versions AS (
    SELECT
        SHA2(
            CONCAT_WS(
                '||',
                invoice_hk,
                hashdiff
            ),
            256
        ) AS invoice_version_hk,
        invoice_hk,
        invoice_date,
        source_year,
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
    WHERE existing.invoice_version_hk = versions.invoice_version_hk
)
{% endif %}
