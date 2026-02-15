-- query 3.2
-- @Mia
-- Moving averages and cumulative measures
-- Moving average
-- business question- compute daily revenue, 7-day moving average, and cumulative revenue
-- daily renevue is the total renevue generated per day
-- 7-day moving average is the average daily revenue over the last 7 days
-- cumulative revenue is the running total revenue from start date up to each day
-- is is useful for year to date og periods KPI
-- daily_renevue_rank identifies the top performance days
-- dayly_renevue_percentile shows relative performance of each day
SELECT 
    d.full_date,
    SUM(f.total_item_value) AS daily_revenue,
    
    -- 7-day moving average of daily revenue
    AVG(SUM(f.total_item_value)) 
        OVER (ORDER BY d.full_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
    
    -- Cumulative revenue
    SUM(SUM(f.total_item_value)) 
        OVER (ORDER BY d.full_date) AS cumulative_revenue,
    
    -- Rank of daily revenue (highest revenue = rank 1)
    RANK() OVER (ORDER BY SUM(f.total_item_value) DESC) AS daily_revenue_rank,
    
    -- Percentile of daily revenue
    PERCENT_RANK() OVER (ORDER BY SUM(f.total_item_value)) AS daily_revenue_percentile

FROM fact_order_sales f
JOIN dim_date d
  ON f.date_key = d.date_key
GROUP BY d.full_date
ORDER BY d.full_date;  


-- Sorted by ranking
-- highest ranking days are 2017-11-24 and 2017-11-25
-- this is black friday weekend in Brazil so makes sense
SELECT 
    d.full_date,
    SUM(f.total_item_value) AS daily_revenue,
    RANK() OVER (ORDER BY SUM(f.total_item_value) DESC) AS daily_revenue_rank,
    PERCENT_RANK() OVER (ORDER BY SUM(f.total_item_value)) AS daily_revenue_percentile
FROM fact_order_sales f
JOIN dim_date d
  ON f.date_key = d.date_key
GROUP BY d.full_date
ORDER BY daily_revenue_rank; 

-- query 4.1
-- @Mia
-- Multi dimensional filtering with EXISTS
-- uses EXISTs and NOT EXISTS to 
-- identify silent customers.(Buisness qestion) The ones that shop but dont leve a review so you dont know if they were satisfied. 
-- That can be further analysed på seeing if the silent customers have multiple orders.

SELECT c.customer_key,
       c.customer_unique_id,
       c.customer_city,
       c.customer_state
FROM dim_customer c
WHERE EXISTS (
    SELECT *
    FROM fact_orders o
    WHERE o.customer_key = c.customer_key
)
AND NOT EXISTS (
    SELECT 1
    FROM fact_order_reviews r
    WHERE r.customer_key = c.customer_key
);

-- query 4.2 
-- @Mia
-- Correlated subquery for comparative analysis
-- Busness question- find products that are more expensive than the average price of all products in theis category
-- the category average is calculated once in category_avg and the outer query compares each products average price with the precomputed average
WITH category_avg AS (
    SELECT p.product_category_name,
           AVG(s.price) AS avg_category_price
    FROM fact_order_sales s
    JOIN dim_products p 
      ON s.product_key = p.product_key
    GROUP BY p.product_category_name
)
SELECT p.product_id,
       p.product_category_name,
       AVG(s.price) AS product_avg_price,
       ca.avg_category_price
FROM fact_order_sales s
JOIN dim_products p 
  ON s.product_key = p.product_key
JOIN category_avg ca
  ON p.product_category_name = ca.product_category_name
GROUP BY p.product_id, p.product_category_name, ca.avg_category_price
HAVING AVG(s.price) > ca.avg_category_price
ORDER BY p.product_category_name, product_avg_price DESC;

-- query 5.1 
-- @Mia
-- Customer/Product profitability analysis
-- Busness question- calculate clv(customer lifetime value)(total revenue-total freight cost)
-- to identifi the customers who spend most money, are most profitable

SELECT c.customer_key,
       c.customer_unique_id,
       c.customer_city,
       c.customer_state,
       SUM(s.total_item_value) AS total_revenue,
       SUM(s.freight_value) AS total_freight,
       (SUM(s.total_item_value) - SUM(s.freight_value)) AS customer_lifetime_value
FROM fact_order_sales s
JOIN dim_customer c
  ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY customer_lifetime_value DESC
LIMIT 10;

-- query 5.2
-- @Mia
-- Performance KPI calculations specific to your domain
-- what percentage of customers have placed more than one order?
-- KPI - repeat purchase rate
-- indicates customer loyalty
-- takes the customers with >1 order ÷ total customers) × 100
-- the rate 3,12% i very low, only 3 of 100 customers buy again
-- Olist relies on new customer aqusition.
-- the customer loyalty is very limited
-- they schold take action with campaigns, loyalty programs etc. for existing customers. 
-- and analyse with the reviews, maye that can give som clues to why
WITH customer_order_counts AS (
    SELECT customer_key,
           COUNT(DISTINCT order_id) AS order_count
    FROM fact_orders
    GROUP BY customer_key
)
SELECT 
    COUNT(*) FILTER (WHERE order_count > 1) * 100.0 / COUNT(*) AS repeat_purchase_rate
FROM customer_order_counts;

-- query 5.2 one more.
-- @Mia
-- KPI-Average Order value
-- buisness question: what is the total value of an order
-- total revenue ÷ total number of orders
-- to measure sale performance
-- results from query:
-- on average each customer brings 136,68 BRL in revenue
-- orders above will be considers high value orders, below low value orders.
-- This information is useful in loyalty programs and campaign targeting
-- this KPI can be uses with repeat purchase rate to calculate clv
SELECT 
    AVG(total_amount) AS avg_order_value
FROM fact_orders
WHERE total_amount IS NOT NULL;





