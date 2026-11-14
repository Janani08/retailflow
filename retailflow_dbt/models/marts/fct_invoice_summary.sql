
{{ config(materialized='table') }}

SELECT
    source_year,
    invoice_id,
    MIN(invoice_date) AS invoice_date,

    COUNT(*) AS transaction_lines,
    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(DISTINCT customer_id) AS known_customer_count,

    MAX(CASE
        WHEN is_cancellation THEN 1 ELSE 0
    END) AS has_cancellation,

    SUM(CASE
        WHEN NOT is_cancellation
             AND quantity > 0 AND unit_price >= 0
        THEN line_amount ELSE 0
    END) AS gross_sales,

    SUM(line_amount) AS net_sales

FROM {{ ref('stg_sales') }}
WHERE invoice_id IS NOT NULL
GROUP BY source_year, invoice_id
