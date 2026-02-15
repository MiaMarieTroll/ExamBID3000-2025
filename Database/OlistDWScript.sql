-- DIMENTION TABLES


-- Date Dimension
DROP TABLE IF EXISTS dim_date CASCADE;
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_week_number SMALLINT NOT NULL,
    day_of_week_name VARCHAR(10) NOT NULL,
    day_of_month SMALLINT NOT NULL,
    day_of_year SMALLINT NOT NULL,
    week_of_year SMALLINT NOT NULL,
    month_number SMALLINT NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    quarter_number SMALLINT NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    year SMALLINT NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN NOT NULL DEFAULT FALSE -- Placeholder, populate separately
);

-- Customer Dimension
DROP TABLE IF EXISTS dim_customer CASCADE;
CREATE TABLE dim_customer(
    customer_key SERIAL PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL UNIQUE,
    customer_zip_code_prefix VARCHAR(20),
    customer_city VARCHAR(50) NOT NULL,
    customer_state VARCHAR(50) NOT NULL
);


-- Product Dimension
DROP TABLE IF EXISTS dim_products CASCADE;
CREATE TABLE dim_products(
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL UNIQUE,
    product_category_name VARCHAR(100) NOT NULL,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);


-- Seller Dimension
DROP TABLE IF EXISTS dim_seller CASCADE;
CREATE TABLE dim_seller (
    seller_key SERIAL PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL UNIQUE,
    seller_city VARCHAR(100),
    seller_state VARCHAR(50)
);

-- Payment Type Dimension
DROP TABLE IF EXISTS dim_payment_type CASCADE;
CREATE TABLE dim_payment_type (
    payment_type_key SERIAL PRIMARY KEY,
    payment_type VARCHAR(50) UNIQUE
);



-- Order Status Dimension
DROP TABLE IF EXISTS dim_order_status CASCADE;
CREATE TABLE dim_order_status (
    order_status_key SERIAL PRIMARY KEY,
    order_status VARCHAR(50) UNIQUE
);

-- FACTS TABLES

-- Fact Order Sales
DROP TABLE IF EXISTS fact_order_sales CASCADE;
CREATE TABLE fact_order_sales(
    order_sales_key BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    order_item_id VARCHAR(50) NOT NULL,
    product_key INT NOT NULL REFERENCES dim_products(product_key),
    date_key INT NOT NULL REFERENCES dim_date(date_key),
    seller_key INT NOT NULL REFERENCES dim_seller(seller_key),
    customer_key INT NOT NULL REFERENCES dim_customer(customer_key),
    shipping_limit_date DATE,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,
    total_item_value DECIMAL(10,2) GENERATED ALWAYS AS (price + freight_value) STORED,
    quantity INT NOT NULL DEFAULT 1,
    profit_margin DECIMAL(10,2),
    CONSTRAINT uq_fact_order_line UNIQUE (order_id, order_item_id)
);
 SELECT* 
 from fact_order_sales;
-- Fact Order Reviews -uten seller og product key
DROP TABLE IF EXISTS fact_order_reviews CASCADE;
CREATE TABLE fact_order_reviews(
    review_key BIGSERIAL PRIMARY KEY,
    review_id VARCHAR(50) NOT NULL UNIQUE,
    order_id VARCHAR(50) NOT NULL,
    customer_key INT NOT NULL REFERENCES dim_customer(customer_key),
    review_date_key INT NOT NULL REFERENCES dim_date(date_key),
    answer_date_key INT REFERENCES dim_date(date_key),
    review_score INT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    has_comment BOOLEAN NOT NULL DEFAULT FALSE,
    has_title BOOLEAN NOT NULL DEFAULT FALSE,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- Fact Payments
DROP TABLE IF EXISTS fact_payments CASCADE;
CREATE TABLE fact_payments (
    payment_key SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    customer_key INT REFERENCES dim_customer(customer_key),
    date_key INT REFERENCES dim_date(date_key),
    payment_type_key INT REFERENCES dim_payment_type(payment_type_key),
    payment_value DECIMAL(12,2)
);


-- Fact Orders 
DROP TABLE IF EXISTS fact_orders CASCADE;
CREATE TABLE fact_orders (
    order_key SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    customer_key INT REFERENCES dim_customer(customer_key),
    date_key INT REFERENCES dim_date(date_key),
    order_status_key INT REFERENCES dim_order_status(order_status_key),
    total_amount DECIMAL(14,2),
    freight_value DECIMAL(12,2)
);



-- INDEXES


-- Fact Order Sales indexes
CREATE INDEX idx_fos_date_product ON fact_order_sales(date_key, product_key);
CREATE INDEX idx_fos_seller_date ON fact_order_sales(seller_key, date_key);
CREATE INDEX idx_fos_customer_date ON fact_order_sales(customer_key, date_key);

-- Fact Order Reviews indexes
CREATE INDEX IF NOT EXISTS idx_reviews_date_score   ON fact_order_reviews(review_date_key, review_score);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_date ON fact_order_reviews(customer_key, review_date_key);
CREATE INDEX IF NOT EXISTS idx_reviews_order_id     ON fact_order_reviews(order_id);

-- Fact Payments index
CREATE INDEX idx_fact_payments_customer ON fact_payments(customer_key);
CREATE INDEX idx_fp_date         ON fact_payments(date_key);
CREATE INDEX idx_fp_payment_type ON fact_payments(payment_type_key);
CREATE INDEX idx_fp_order        ON fact_payments(order_id);

-- Fact Orders index
CREATE INDEX idx_fact_orders_customer ON fact_orders(customer_key);
CREATE INDEX idx_fo_status ON fact_orders(order_status_key);