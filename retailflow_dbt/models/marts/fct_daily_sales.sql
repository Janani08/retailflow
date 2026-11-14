
{{ config(materialized='table') }}

SELECT
    CAST(invoice_date AS DATE) AS sales_date,
    COUNT(*) AS transaction_lines,
    COUNT(DISTINCT source_year, invoice_id) AS invoice_count,

    SUM(CASE
        WHEN NOT is_cancellation
             AND quantity > 0 AND unit_price >= 0
        THEN line_amount ELSE 0
    END) AS gross_sales,

    SUM(CASE
        WHEN is_cancellation
        THEN line_amount ELSE 0
    END) AS cancellation_amount,

    SUM(line_amount) AS net_sales

FROM {{ ref('stg_sales') }}
WHERE invoice_date IS NOT NULL
GROUP BY 1
