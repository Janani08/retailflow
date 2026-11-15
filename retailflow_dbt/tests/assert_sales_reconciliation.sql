
WITH daily AS (
    SELECT
        SUM(gross_sales) AS gross_sales,
        SUM(net_sales) AS net_sales
    FROM {{ ref('fct_daily_sales') }}
),

monthly AS (
    SELECT
        SUM(gross_sales) AS gross_sales,
        SUM(net_sales) AS net_sales
    FROM {{ ref('fct_monthly_sales') }}
),

raw_totals AS (
    SELECT
        SUM(
            CASE
                WHEN NOT is_cancellation
                     AND quantity > 0
                     AND unit_price >= 0
                THEN line_amount
                ELSE 0
            END
        ) AS gross_sales,
        SUM(line_amount) AS net_sales
    FROM {{ ref('stg_sales') }}
    WHERE invoice_date IS NOT NULL
)

SELECT
    daily.gross_sales AS daily_gross,
    monthly.gross_sales AS monthly_gross,
    raw_totals.gross_sales AS raw_gross,
    daily.net_sales AS daily_net,
    monthly.net_sales AS monthly_net,
    raw_totals.net_sales AS raw_net
FROM daily
CROSS JOIN monthly
CROSS JOIN raw_totals
WHERE
    ABS(daily.gross_sales - monthly.gross_sales) > 0.01
    OR ABS(daily.gross_sales - raw_totals.gross_sales) > 0.01
    OR ABS(daily.net_sales - monthly.net_sales) > 0.01
    OR ABS(daily.net_sales - raw_totals.net_sales) > 0.01
    OR daily.gross_sales IS NULL
    OR monthly.gross_sales IS NULL
    OR raw_totals.gross_sales IS NULL
    OR daily.net_sales IS NULL
    OR monthly.net_sales IS NULL
    OR raw_totals.net_sales IS NULL
