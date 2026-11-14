
{{ config(materialized='table') }}

SELECT
    p.product_hk,
    p.product_bk AS product_id,

    COUNT(DISTINCT s.source_year, s.invoice_id) AS invoice_count,

    SUM(CASE
        WHEN NOT s.is_cancellation AND s.quantity > 0
        THEN s.quantity ELSE 0
    END) AS units_sold,

    SUM(CASE
        WHEN s.is_cancellation
        THEN ABS(s.quantity) ELSE 0
    END) AS cancellation_units,

    SUM(CASE
        WHEN NOT s.is_cancellation
             AND s.quantity > 0 AND s.unit_price >= 0
        THEN s.line_amount ELSE 0
    END) AS gross_sales,

    SUM(s.line_amount) AS net_sales

FROM {{ ref('stg_sales') }} s
JOIN {{ ref('hub_product') }} p
    ON SHA2(s.product_id, 256) = p.product_hk

GROUP BY p.product_hk, p.product_bk
