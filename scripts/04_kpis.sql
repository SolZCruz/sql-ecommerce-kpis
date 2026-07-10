-- ============================================================
-- 04_kpis.sql
-- ============================================================

-- ------------------------------------------------------------
-- KPI 1: Average Order Value (AOV)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_1 AS
SELECT
    'kpi_1' AS kpi_name,
    ROUND(AVG(order_amount_old), 2)::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM clean_table;

-- ------------------------------------------------------------
-- KPI 2: Overall Gross Margin
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_2 AS
SELECT
    'kpi_2' AS kpi_name,
    ROUND( (SUM(order_amount_old) - SUM(cost)) / SUM(order_amount_old), 6)::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM clean_table;

-- ------------------------------------------------------------
-- KPI 3: Return Rate
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_3 AS
SELECT
    'kpi_3' AS kpi_name,
    ROUND( SUM(is_return)::NUMERIC / COUNT(*), 6)::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM clean_table;

-- ------------------------------------------------------------
-- KPI 4: Median Order Amount
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_4 AS
SELECT
    'kpi_4' AS kpi_name,
    ROUND(
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_amount_old))::NUMERIC,
        2
    )::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM clean_table;

-- ------------------------------------------------------------
-- KPI 5: Return Rate by Payment Method
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_5 AS
SELECT
    'kpi_5' AS kpi_name,
    ROUND( SUM(is_return)::NUMERIC / COUNT(*), 6)::TEXT AS kpi_value,
    payment_method::TEXT AS kpi_key
FROM clean_table
GROUP BY payment_method;

-- ------------------------------------------------------------
-- KPI 6: High Value Segment GMV Share (premium + platinum)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_6 AS
WITH gmv AS (
    SELECT
        SUM(order_amount_old) AS total_gmv,
        SUM(CASE WHEN customer_segment IN ('premium','platinum') THEN order_amount_old ELSE 0 END) AS hv_gmv
    FROM clean_table
)
SELECT
    'kpi_6' AS kpi_name,
    ROUND(hv_gmv / total_gmv, 6)::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM gmv;

-- ------------------------------------------------------------
-- KPI 7: Below Target Margin Rate
-- Reglas de margen mínimo por segmento:
--   standard >= 0.40 | premium >= 0.30 | platinum >= 0.25
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_7 AS
WITH base AS (
    SELECT
        customer_segment,
        (order_amount_old - cost) / order_amount_old AS gross_margin
    FROM clean_table
),
eligible AS (
    SELECT
        customer_segment,
        gross_margin,
        CASE
            WHEN customer_segment = 'standard' THEN 0.40
            WHEN customer_segment = 'premium'  THEN 0.30
            WHEN customer_segment = 'platinum' THEN 0.25
        END AS floor_margin
    FROM base
    WHERE customer_segment IN ('standard','premium','platinum')
)
SELECT
    'kpi_7' AS kpi_name,
    ROUND(
        1.0 * SUM(
            CASE
                WHEN customer_segment = 'platinum' AND gross_margin <= floor_margin THEN 1
                WHEN customer_segment IN ('standard','premium') AND gross_margin < floor_margin THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        6
    )::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM eligible;

-- ------------------------------------------------------------
-- KPI 8: Top GMV Month
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_8 AS
WITH month_gmv AS (
    SELECT
        TO_CHAR(order_date, 'YYYY-MM') AS month_key,
        SUM(order_amount_old) AS gmv
    FROM clean_table
    GROUP BY month_key
)
SELECT
    'kpi_8' AS kpi_name,
    month_key::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM month_gmv
ORDER BY gmv DESC, month_key DESC
LIMIT 1;

-- ------------------------------------------------------------
-- KPI 9: Latest Month-over-Month GMV Growth %
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_9 AS
WITH month_gmv AS (
    SELECT
        TO_CHAR(order_date, 'YYYY-MM') AS month_key,
        SUM(order_amount_old) AS gmv
    FROM clean_table
    GROUP BY month_key
),
with_lag AS (
    SELECT
        month_key,
        gmv,
        LAG(gmv) OVER (ORDER BY month_key) AS prev_gmv
    FROM month_gmv
),
latest AS (
    SELECT * FROM with_lag ORDER BY month_key DESC LIMIT 1
)
SELECT
    'kpi_9' AS kpi_name,
    ROUND( (gmv - prev_gmv) / prev_gmv, 6)::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM latest;

-- ------------------------------------------------------------
-- KPI 10: Max Payment Mix Shift (mes a mes)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW kpi_10 AS
WITH with_month AS (
    SELECT
        TO_CHAR(order_date, 'YYYY-MM') AS month_key,
        payment_method
    FROM clean_table
),
counts AS (
    SELECT month_key, payment_method, COUNT(*) AS n
    FROM with_month
    GROUP BY month_key, payment_method
),
totals AS (
    SELECT month_key, SUM(n) AS total
    FROM counts
    GROUP BY month_key
),
shares AS (
    SELECT c.month_key, c.payment_method, 1.0 * c.n / t.total AS share
    FROM counts c
    JOIN totals t USING (month_key)
),
diffs AS (
    SELECT
        payment_method,
        month_key,
        ABS(share - LAG(share) OVER (PARTITION BY payment_method ORDER BY month_key)) AS diff
    FROM shares
)
SELECT
    'kpi_10' AS kpi_name,
    ROUND(MAX(diff), 6)::TEXT AS kpi_value,
    NULL::TEXT AS kpi_key
FROM diffs
WHERE diff IS NOT NULL;

SELECT * FROM kpi_10

-- ------------------------------------------------------------
-- KPI individualmente
-- ------------------------------------------------------------
-- SELECT * FROM kpi_10
