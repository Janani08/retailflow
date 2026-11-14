
{{ config(materialized='table') }}

SELECT
    c.customer_hk,
    c.customer_bk AS customer_id,

    MIN(s.invoice_date)::DATE AS first_purchase_date,
    MAX(s.invoice_date)::DATE AS last_activity_date,

    COUNT(DISTINCT
        CASE WHEN NOT s.is_cancellation
                   AND s.quantity > 0
             THEN s.source_year || '||' || s.invoice_id
        END
    ) AS purchase_count,

    SUM(CASE
        WHEN NOT s.is_cancellation
             AND s.quantity > 0 AND s.unit_price >= 0
        THEN s.line_amount ELSE 0
    END) AS gross_sales,

    SUM(s.line_amount) AS net_sales

FROM {{ ref('stg_sales') }} s
JOIN {{ ref('hub_customer') }} c
    ON SHA2(s.customer_id, 256) = c.customer_hk

GROUP BY c.customer_hk, c.customer_bk
