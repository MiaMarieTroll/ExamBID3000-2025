-- Queries Christin
--***********************************************************************************************
-- query 1.1 — Time-based Trend: Year-over-Year (YoY) growth by month
-- Purpose: Compare this year's monthly revenue to the same month last year.
-- Grain: (year, month). Uses fact_orders + dim_date.
-- Output:
--   year, month, revenue, prev_year_revenue, yoy_pct (% change vs prior year)
-- NULL values appear first because LAG() cannot find a previous year's, no 2015 data to compare 2016 against.
-- LAG is a SQL window function that retrieves the value from a previous row in the result set.
WITH m AS (
  SELECT d.year,
         d.month_number AS month,
         SUM(o.total_amount) AS revenue
  FROM fact_orders o
  JOIN dim_date d ON d.date_key = o.date_key
  GROUP BY d.year, d.month_number
)
SELECT
  year,
  month,
  revenue,
  LAG(revenue) OVER (PARTITION BY month ORDER BY year) AS prev_year_revenue,
  ROUND(
    (revenue - LAG(revenue) OVER (PARTITION BY month ORDER BY year))
    / NULLIF(LAG(revenue) OVER (PARTITION BY month ORDER BY year), 0) * 100, 2
  ) AS yoy_pct
FROM m
ORDER BY year, month;

--***************************************************************************
-- query 1.2 Time-based Trend: Seasonal pattern identification (index)
-- Purpose: Identify which months over/under-perform vs the overall average.
-- Grain: month across all years.
-- Output:
--   month, avg_revenue (mean across years), seasonality_index (= avg_revenue / overall_avg * 100)
WITH m AS (
  SELECT d.year, d.month_number AS month, SUM(o.total_amount) AS revenue
  FROM fact_orders o
  JOIN dim_date d ON d.date_key = o.date_key
  GROUP BY d.year, d.month_number
),
avg_by_month AS (
  SELECT month, AVG(revenue) AS avg_rev FROM m GROUP BY month
),
overall AS (
  SELECT AVG(revenue) AS overall_avg FROM m
)
SELECT
  a.month,
  ROUND(a.avg_rev, 2) AS avg_revenue,
  ROUND(a.avg_rev / NULLIF(o.overall_avg, 0) * 100, 2) AS seasonality_index
FROM avg_by_month a
CROSS JOIN overall o
ORDER BY a.month;

--***************************************************************************************
-- query 2.1 — Drill-down/Roll-up: Multi-level aggregation (Year → Quarter → Month)
-- Purpose: show revenue at month level + subtotals per quarter and per year (no NULLs).
-- Grain: ROLLUP over (year, quarter_number, month_number).
-- Output: level_label, year, quarter, month, revenue.

SELECT
  CASE
    WHEN GROUPING(d.year)=1 AND GROUPING(d.quarter_number)=1 AND GROUPING(d.month_number)=1 THEN 'GRAND TOTAL'
    WHEN GROUPING(d.quarter_number)=1 AND GROUPING(d.month_number)=1 THEN 'YEAR TOTAL'
    WHEN GROUPING(d.month_number)=1 THEN 'QUARTER TOTAL'
    ELSE 'MONTH'
  END AS level_label,
  d.year,
  d.quarter_number,
  d.month_number,
  SUM(o.total_amount) AS revenue
FROM fact_orders o
JOIN dim_date d ON d.date_key = o.date_key
GROUP BY ROLLUP (d.year, d.quarter_number, d.month_number)
ORDER BY
  GROUPING(d.year),    d.year,
  GROUPING(d.quarter_number), d.quarter_number,
  GROUPING(d.month_number),   d.month_number;

--*******************************************************************************************
-- query 2.2 — Drill-down/Roll-up: hierarchical dimension (State → City)
-- Purpose: Roll up revenue from city to state and to grand total (keep rollup, no NULLs shown).
-- Grain: ROLLUP(seller_state, seller_city).
-- Output: seller_state, seller_city (labeled as CITY / STATE SUBTOTAL / GRAND TOTAL), revenue.

SELECT
  CASE
    WHEN GROUPING(s.seller_state) = 1 THEN 'ALL STATES'-- grand total level
    ELSE s.seller_state
  END AS seller_state,
  CASE
    WHEN GROUPING(s.seller_state) = 1 AND GROUPING(s.seller_city) = 1 THEN 'GRAND TOTAL'
    WHEN GROUPING(s.seller_city)  = 1 THEN 'STATE SUBTOTAL'
    ELSE s.seller_city
  END AS seller_city,
  SUM(f.total_item_value) AS revenue
FROM fact_order_sales f
JOIN dim_seller s ON s.seller_key = f.seller_key
GROUP BY ROLLUP (s.seller_state, s.seller_city)
-- order: cities - state subtotal - grand total
ORDER BY
  CASE WHEN GROUPING(s.seller_state)=1 THEN 1 ELSE 0 END,
  s.seller_state,
  CASE WHEN GROUPING(s.seller_city)=1 THEN 1 ELSE 0 END,
  s.seller_city;

--****************************************************************************************  
-- query 3.1 — Advanced Window: Top sellers with ranking
-- Purpose: Rank all sellers by revenue and compute a percentile from the TOP (1.0000 = best).
-- Grain: one row per seller (nationwide).
-- Output: seller_id, revenue, rank_num (1 = highest), pct_rank_top (1.0000 best → 0.0000 worst).
WITH seller_revenue AS (
  SELECT s.seller_id, SUM(f.total_item_value) AS revenue
  FROM fact_order_sales f
  JOIN dim_seller s ON s.seller_key = f.seller_key
  GROUP BY s.seller_id
)
SELECT
  seller_id,
  revenue,
  RANK() OVER (ORDER BY revenue DESC) AS rank_num, -- 1 = høyest
  ROUND((1 - PERCENT_RANK() OVER (ORDER BY revenue DESC))::numeric, 4)     AS pct_rank_top
FROM seller_revenue
ORDER BY revenue DESC;
