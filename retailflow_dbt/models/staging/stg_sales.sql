
{{ config(materialized='view') }}

WITH source_data AS (
    SELECT *
    FROM {{ source('retail_raw', 'SALES_INGEST_TEST') }}
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

FROM source_data
