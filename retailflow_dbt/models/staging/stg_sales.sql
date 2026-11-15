
{{ config(materialized='view') }}

WITH source_data AS (
    SELECT *
    FROM {{ source('retail_raw', 'SALES_INGEST_TEST') }}
),

first_file_invoices AS (
    SELECT DISTINCT
        TRIM(INVOICE) AS invoice_id
    FROM source_data
    WHERE SOURCE_YEAR = '2009-2010'
      AND INVOICE IS NOT NULL
),

deduplicated AS (
    SELECT s.*
    FROM source_data s
    WHERE NOT (
        s.SOURCE_YEAR = '2010-2011'
        AND s.INVOICE IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM first_file_invoices f
            WHERE f.invoice_id = TRIM(s.INVOICE)
        )
    )
)

SELECT
    TRIM(INVOICE) AS invoice_id,
    TRIM(STOCK_CODE) AS product_id,
    TRIM(DESCRIPTION) AS product_description,
    QUANTITY AS quantity,
    INVOICE_DATE AS invoice_date,
    PRICE AS unit_price,
    NULLIF(TRIM(CUSTOMER_ID), '') AS customer_id,
    TRIM(COUNTRY) AS country,
    SOURCE_YEAR AS source_year,

    CASE
        WHEN INVOICE ILIKE 'C%' OR QUANTITY < 0
        THEN TRUE
        ELSE FALSE
    END AS is_cancellation,

    QUANTITY * PRICE AS line_amount

FROM deduplicated
