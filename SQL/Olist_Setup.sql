-- Create and select the project database
CREATE DATABASE IF NOT EXISTS olist_ecommerce;
USE olist_ecommerce;

-- Enable local CSV loading
-- May require MySQL administrative privileges
SET GLOBAL local_infile = 1;

-- Create project tables
-- Run this section on a fresh database, or remove existing tables
-- before rerunning the setup script.

CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(50),
    customer_state VARCHAR(2)
);

CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(15),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

CREATE TABLE reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(50),
    review_comment_message VARCHAR(100),
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(50),
    product_name_length INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE product_category_name (
    product_category_name VARCHAR(50),
    product_category_name_english VARCHAR(50)
);

CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(20),
    seller_city VARCHAR(35),
    seller_state VARCHAR(2)
);

CREATE TABLE geolocation_city (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat DECIMAL(11,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(30),
    geolocation_state VARCHAR(2)
);


-- Load customer data
-- Replace the placeholder with the actual path to your CSV file.
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load order data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load order item data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load payment data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load review data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load product data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load product category translation
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/product_category_name_translation.csv'
INTO TABLE product_category_name
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load seller data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Load geolocation data
LOAD DATA LOCAL INFILE 'YOUR_DATASET_FOLDER/olist_geolocation_dataset.csv'
INTO TABLE geolocation_city
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Clean invalid zero dates in orders

UPDATE orders
SET order_approved_at = NULL
WHERE CAST(order_approved_at AS CHAR) = '0000-00-00 00:00:00';

UPDATE orders
SET order_delivered_carrier_date = NULL
WHERE CAST(order_delivered_carrier_date AS CHAR) = '0000-00-00 00:00:00';

UPDATE orders
SET order_delivered_customer_date = NULL
WHERE CAST(order_delivered_customer_date AS CHAR) = '0000-00-00 00:00:00';

-- Clean invalid zero dates in reviews

UPDATE reviews
SET review_creation_date = NULL
WHERE CAST(review_creation_date AS CHAR) = '0000-00-00 00:00:00';

UPDATE reviews
SET review_answer_timestamp = NULL
WHERE CAST(review_answer_timestamp AS CHAR) = '0000-00-00 00:00:00';

-- Add primary keys

ALTER TABLE customers
ADD PRIMARY KEY (customer_id);

ALTER TABLE orders
ADD PRIMARY KEY (order_id);

ALTER TABLE order_items
ADD PRIMARY KEY (order_id, order_item_id);

ALTER TABLE payments
ADD PRIMARY KEY (order_id, payment_sequential);

ALTER TABLE products
ADD PRIMARY KEY (product_id);

ALTER TABLE product_category_name
ADD PRIMARY KEY (product_category_name);

ALTER TABLE sellers
ADD PRIMARY KEY (seller_id);

ALTER TABLE reviews
ADD PRIMARY KEY (review_id, order_id);

-- Add foreign keys

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE products
ADD CONSTRAINT fk_products_category
FOREIGN KEY (product_category_name)
REFERENCES product_category_name(product_category_name);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_seller
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

ALTER TABLE payments
ADD CONSTRAINT fk_payments_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- Verify imported row counts

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'product_category_name', COUNT(*) FROM product_category_name
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation_city', COUNT(*) FROM geolocation_city;