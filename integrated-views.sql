-- Project 04 - Integrated Project with Views and Documentation
-- End-to-end SQL pipeline: staging DDL, ETL (COPY), dimensional model, analytical views

-- =========================
-- 1. Staging tables (DDL)
-- =========================

CREATE TABLE IF NOT EXISTS staging_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE IF NOT EXISTS staging_geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city TEXT,
    geolocation_state TEXT
);

CREATE TABLE IF NOT EXISTS staging_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

CREATE TABLE IF NOT EXISTS staging_order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price NUMERIC,
    freight_value NUMERIC
);

CREATE TABLE IF NOT EXISTS staging_order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC
);

CREATE TABLE IF NOT EXISTS staging_order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

CREATE TABLE IF NOT EXISTS staging_products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

CREATE TABLE IF NOT EXISTS staging_product_category_name_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

CREATE TABLE IF NOT EXISTS staging_sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

-- =========================
-- 2. Load CSVs (ETL)
-- =========================
-- Adjust file paths if needed

COPY staging_customers
FROM 'D:/PostgreSQL/data/olist/olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_geolocation
FROM 'D:/PostgreSQL/data/olist/olist_geolocation_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_orders
FROM 'D:/PostgreSQL/data/olist/olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_order_items
FROM 'D:/PostgreSQL/data/olist/olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_order_payments
FROM 'D:/PostgreSQL/data/olist/olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_order_reviews
FROM 'D:/PostgreSQL/data/olist/olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_products
FROM 'D:/PostgreSQL/data/olist/olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY staging_product_category_name_translation
FROM 'D:/PostgreSQL/data/olist/olist_product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;

COPY staging_sellers
FROM 'D:/PostgreSQL/data/olist/olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

-- =========================
-- 3. Dimensional model
-- =========================

-- dim_time
CREATE TABLE IF NOT EXISTS dim_time AS
SELECT DISTINCT
    DATE(order_purchase_timestamp) AS date_key,
    EXTRACT(YEAR FROM DATE(order_purchase_timestamp)) AS year,
    EXTRACT(MONTH FROM DATE(order_purchase_timestamp)) AS month,
    EXTRACT(DAY FROM DATE(order_purchase_timestamp)) AS day,
    TO_CHAR(DATE(order_purchase_timestamp), 'YYYY-MM') AS year_month,
    TO_CHAR(DATE(order_purchase_timestamp), 'Q') AS quarter,
    TO_CHAR(DATE(order_purchase_timestamp), 'Day') AS day_name
FROM staging_orders
WHERE order_purchase_timestamp IS NOT NULL;

-- dim_customer
CREATE TABLE IF NOT EXISTS dim_customer AS
SELECT DISTINCT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
FROM staging_customers c;

-- dim_product
CREATE TABLE IF NOT EXISTS dim_product AS
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging_products p
LEFT JOIN staging_product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

-- dim_seller
CREATE TABLE IF NOT EXISTS dim_seller AS
SELECT
    seller_id,
    seller_city,
    seller_state
FROM staging_sellers;

-- dim_payment
CREATE TABLE IF NOT EXISTS dim_payment AS
SELECT DISTINCT
    payment_type
FROM staging_order_payments;

-- fact_sales
CREATE TABLE IF NOT EXISTS fact_sales AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,
    DATE(o.order_purchase_timestamp) AS date_key,
    op.payment_type,
    oi.price,
    oi.freight_value,
    (oi.price - COALESCE(0, 0) + oi.freight_value) AS revenue_net
FROM staging_order_items oi
JOIN staging_orders o
    ON oi.order_id = o.order_id
LEFT JOIN staging_order_payments op
    ON oi.order_id = op.order_id;

-- =========================
-- 4. Analytical views (KPIs)
-- =========================

-- 1) Monthly revenue and orders
CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT
    TO_CHAR(date_key, 'YYYY-MM') AS year_month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(revenue_net) AS total_revenue,
    AVG(revenue_net) AS aov
FROM fact_sales
GROUP BY TO_CHAR(date_key, 'YYYY-MM')
ORDER BY year_month;

-- 2) Top 10 customers by revenue
CREATE OR REPLACE VIEW v_top_10_customers AS
SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(revenue_net) AS total_revenue
FROM fact_sales
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 3) Top 10 products by revenue
CREATE OR REPLACE VIEW v_top_10_products AS
SELECT
    product_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(revenue_net) AS total_revenue
FROM fact_sales
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 4) Revenue by product category
CREATE OR REPLACE VIEW v_revenue_by_category AS
SELECT
    p.product_category_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.revenue_net) AS total_revenue
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

-- 5) Revenue by customer state
CREATE OR REPLACE VIEW v_revenue_by_state AS
SELECT
    c.customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.revenue_net) AS total_revenue
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- 6) Revenue by payment type
CREATE OR REPLACE VIEW v_revenue_by_payment_type AS
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(revenue_net) AS total_revenue
FROM fact_sales
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- 7) Revenue by seller state
CREATE OR REPLACE VIEW v_revenue_by_seller_state AS
SELECT
    s.seller_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.revenue_net) AS total_revenue
FROM fact_sales f
JOIN dim_seller s ON f.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY total_revenue DESC;

-- 8) Delivery performance (on-time rate)
CREATE OR REPLACE VIEW v_delivery_performance AS
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN o.order_id END) AS on_time_orders,
    COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN o.order_id END) * 1.0 / COUNT(DISTINCT o.order_id) AS on_time_rate
FROM staging_orders o
JOIN fact_sales f ON o.order_id = f.order_id
WHERE o.order_delivered_customer_date IS NOT NULL;