/*
  File: dim_date.sql
  Source reference: Generated with GoogleAI (via Google AI). Original idea and structure adapted from
  a Google search result on creating a date dimension table in PostgreSQL using generate_series.
*/

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

INSERT INTO dim_date (
    date_key,
    full_date,
    day_of_week_number,
    day_of_week_name,
    day_of_month,
    day_of_year,
    week_of_year,
    month_number,
    month_name,
    quarter_number,
    quarter_name,
    year,
    is_weekend
)
SELECT
    TO_CHAR(datum, 'YYYYMMDD')::INT AS date_key,
    datum AS full_date,
    EXTRACT(ISODOW FROM datum) AS day_of_week_number,
    TO_CHAR(datum, 'Day') AS day_of_week_name,
    EXTRACT(DAY FROM datum) AS day_of_month,
    EXTRACT(DOY FROM datum) AS day_of_year,
    EXTRACT(WEEK FROM datum) AS week_of_year,
    EXTRACT(MONTH FROM datum) AS month_number,
    TO_CHAR(datum, 'Month') AS month_name,
    EXTRACT(QUARTER FROM datum) AS quarter_number,
    CASE
        WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'First'
        WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Second'
        WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Third'
        WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Fourth'
    END AS quarter_name,
    EXTRACT(YEAR FROM datum) AS year,
    CASE
        WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM generate_series('2000-01-01'::DATE, '2020-12-31'::DATE, '1 day'::INTERVAL) AS datum;
