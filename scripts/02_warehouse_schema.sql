/* =========================================================
   OLIST E-COMMERCE DATABASE - SCHEMA CREATION & IMPORT
========================================================= */

-- 1. CLEANUP (Drop tables if they exist to start fresh)
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS geolocation CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS category_translation CASCADE;


-- 2. CREATE TABLES (Defining the Schema)
-- A. Geolocation (Must be first because Customers/Sellers refer to it)
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT PRIMARY KEY,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

-- B. Customers
CREATE TABLE customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- C. Sellers
CREATE TABLE sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- D. Products
CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght FLOAT,
    product_description_lenght FLOAT,
    product_photos_qty FLOAT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT,
    product_category_name_english VARCHAR(100)
);

-- E. Orders (Central Table)
CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- F. Order Items (The "Details" Table)
CREATE TABLE order_items (
    order_id VARCHAR(32),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price FLOAT,
    freight_value FLOAT
);

-- G. Payments
CREATE TABLE order_payments (
    order_id VARCHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value FLOAT
);

-- H. Reviews
CREATE TABLE order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- 3. IMPORT DATA (The "COPY" Command)
-- 1. Load Geolocation
COPY geolocation FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\geolocation.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 2. Load Customers
COPY customers FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\customers.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 3. Load Sellers
COPY sellers FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\sellers.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 4. Load Products
COPY products FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\products.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 5. Load Orders
COPY orders FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\orders.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 6. Load Order Items
COPY order_items FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\order_items.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 7. Load Order Payments
COPY order_payments FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\order_payments.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 8. Load Order Reviews
COPY order_reviews FROM 'D:\Data_Science\Projects\Portfolio_Projects\Olist-Logistics-Analysis\data\processed\order_reviews.csv' 
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


-- 4. ADD FOREIGN KEYS (The "Star Schema" Connections)
-- Orders -> Customers
ALTER TABLE orders ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

-- Order Items -> Orders
ALTER TABLE order_items ADD CONSTRAINT fk_items_orders 
FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- Order Items -> Products
ALTER TABLE order_items ADD CONSTRAINT fk_items_products 
FOREIGN KEY (product_id) REFERENCES products(product_id);

-- Order Items -> Sellers
ALTER TABLE order_items ADD CONSTRAINT fk_items_sellers 
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

-- Payments -> Orders
ALTER TABLE order_payments ADD CONSTRAINT fk_payments_orders 
FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- Reviews -> Orders
ALTER TABLE order_reviews ADD CONSTRAINT fk_reviews_orders 
FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- Customers -> Geolocation
-- ALTER TABLE customers ADD CONSTRAINT fk_cust_geo 
-- FOREIGN KEY (customer_zip_code_prefix) REFERENCES geolocation(geolocation_zip_code_prefix);


/* =========================================================
   DATABASE HEALTH CHECK
========================================================= */

-- 1. ROW COUNT CHECK
SELECT '1. Customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT '2. Geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT '3. Orders', COUNT(*) FROM orders
UNION ALL
SELECT '4. Order Items', COUNT(*) FROM order_items
UNION ALL
SELECT '5. Products', COUNT(*) FROM products
UNION ALL
SELECT '6. Payments', COUNT(*) FROM order_payments
UNION ALL
SELECT '7. Reviews', COUNT(*) FROM order_reviews;

-- 2. RELATIONSHIP TEST (The "Star Schema" Check)
SELECT 
    o.order_id,
    o.order_purchase_timestamp,
    c.customer_city,
    p.product_category_name_english,
    i.price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items i ON o.order_id = i.order_id
JOIN products p ON i.product_id = p.product_id
LIMIT 5;

-- 3. THE "ORPHAN ZIP CODE" CHECK
SELECT 
    COUNT(*) as missing_zips 
FROM customers c
LEFT JOIN geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;



