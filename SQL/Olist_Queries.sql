-- ============================================================================
-- OLIST E-COMMERCE BUSINESS ANALYSIS USING MYSQL
-- ============================================================================

-- PROJECT OVERVIEW
-- Analyze Olist's Brazilian e-commerce data to understand key business
-- performance areas including orders, sales, customers, payments,
-- products, sellers, and delivery performance.


-- PROBLEM STATEMENT
-- How can Olist's e-commerce data be analyzed to evaluate sales and order
-- performance, understand customer and payment behavior, identify
-- high-performing products and sellers, and assess delivery performance?


-- PROJECT OBJECTIVES
-- 1. Analyze sales and order performance across different order statuses
--    and time periods.
--
-- 2. Understand customer purchasing behavior and identify high-value
--    customers.
--
-- 3. Analyze payment methods, payment values, and spending patterns.
--
-- 4. Evaluate product and category performance based on sales and revenue.
--
-- 5. Assess delivery performance and identify late-delivery patterns.
--
-- 6. Analyze seller performance based on revenue and product sales.


-- ============================================================================
-- 1. ORDERS & SALES PERFORMANCE
-- ============================================================================
-- Analyze order activity, order status, order timing, and sales performance.

USE OLIST_ECOMMERCE;

-- Q1. What different order statuses exist in the dataset?

SELECT DISTINCT 
	ORDER_STATUS
FROM ORDERS;

-- Q2. How many orders are there for each order_status?
SELECT  ORDER_STATUS , COUNT(*) AS ORDER_COUNT FROM ORDERS
GROUP BY ORDER_STATUS;

-- Q3.  Show only the orders that have been canceled.

SELECT 
    ORDER_ID, CUSTOMER_ID, ORDER_PURCHASE_TIMESTAMP
FROM
    ORDERS
WHERE
    ORDER_STATUS = 'CANCELED';

-- Q4. How many orders don't have a customer delivery date?

SELECT COUNT(*) as ORDERS_WITHOUT_DELIVERY_DATE
FROM ORDERS 
WHERE  ORDER_DELIVERED_CUSTOMER_DATE IS NULL;



-- ============================================================================
-- 2. PAYMENTS & CUSTOMER BEHAVIOR
-- ============================================================================
-- Analyze payment patterns.


-- Q5.  Which payment method do customers use most?
  
SELECT 	
	PAYMENT_TYPE, 
    COUNT(*) AS PAYMENT_COUNT
FROM PAYMENTS
GROUP BY PAYMENT_TYPE  
ORDER BY PAYMENT_COUNT DESC
LIMIT 1;

-- Q6. What is the total payment value for each payment type?

SELECT 
	PAYMENT_TYPE,
    SUM(PAYMENT_VALUE) AS TOTAL_PAY_VALUE  
FROM PAYMENTS
GROUP BY PAYMENT_TYPE 
ORDER BY TOTAL_PAY_VALUE DESC;

-- Q7. How does payment performance vary across payment types?
-- Compare payment count, total payment value, and average payment value by payment type

 SELECT 
	PAYMENT_TYPE,
    COUNT(*) AS NUMBER_OF_PAYMENT,
    SUM(PAYMENT_VALUE) AS TOTAL_PAY_VALUE,
    AVG(PAYMENT_VALUE) AS AVG_PAY_VALUE 
FROM PAYMENTS
GROUP BY PAYMENT_TYPE
ORDER BY TOTAL_PAY_VALUE DESC ;

-- Q8. How can we categorize payments based on their payment value?
-- Categorize payments into high, medium, and low value groups and count the payments in each group.

SELECT 
CASE 
		WHEN PAYMENT_VALUE >= 200 THEN 'HIGH VALUE'
		WHEN PAYMENT_VALUE BETWEEN 100 AND 199.99 THEN 'MEDIUM VALUE'
		ELSE  'LOW VALUE'
	END  AS PAYMENT_CATEGORY ,
	COUNT(*) AS PAYMENT_COUNT
FROM PAYMENTS 
GROUP BY PAYMENT_CATEGORY 
;
   
-- Customer purchasing behavior

-- Q9. What are the top 10 customers by total amount spent?
-- Calculate total spending per customer and return the top 10 customers.

SELECT 
	c.CUSTOMER_UNIQUE_ID, 
    SUM(p.PAYMENT_VALUE) AS TOTAL_AMOUNT_SPEND
FROM CUSTOMERS c
INNER JOIN ORDERS o 
	ON c.CUSTOMER_ID = o.CUSTOMER_ID
INNER JOIN PAYMENTS p 
	ON o.ORDER_ID = p.ORDER_ID
GROUP BY c.CUSTOMER_UNIQUE_ID
ORDER BY TOTAL_AMOUNT_SPEND DESC
LIMIT 10;

-- Q10. Find the top 10 customers by total spending, but also show how many orders each customer made.
-- Compare total spending and order count for the top-spending customers.

SELECT
	c.CUSTOMER_UNIQUE_ID, 
    SUM(p.PAYMENT_VALUE) AS TOTAL_AMOUNT_SPEND,  
    COUNT(DISTINCT o.ORDER_ID) AS ORDER_COUNT
FROM CUSTOMERS c
INNER JOIN ORDERS o 
	ON c.CUSTOMER_ID = o.CUSTOMER_ID
INNER JOIN PAYMENTS p 
	ON o.ORDER_ID = p.ORDER_ID
GROUP BY c.CUSTOMER_UNIQUE_ID
ORDER BY TOTAL_AMOUNT_SPEND DESC
LIMIT 10;

-- Q11.  Find customers whose total spending is greater than the average total spending per customer.

SELECT 
	c.CUSTOMER_UNIQUE_ID, 
    SUM(p.PAYMENT_VALUE) AS TOTAL_SPENDING 
FROM CUSTOMERS c 
INNER JOIN ORDERS o 
	ON c.CUSTOMER_ID = o.CUSTOMER_ID
INNER JOIN PAYMENTS p 
	ON o.ORDER_ID = p.ORDER_ID
GROUP BY c.CUSTOMER_UNIQUE_ID
HAVING SUM(p.PAYMENT_VALUE) > 
	(SELECT AVG(TOTAL_SPENDING) 
	FROM (
		SELECT
            c2.CUSTOMER_UNIQUE_ID,
            SUM(p2.PAYMENT_VALUE) AS TOTAL_SPENDING
        FROM CUSTOMERS c2
        INNER JOIN ORDERS o2
            ON c2.CUSTOMER_ID = o2.CUSTOMER_ID
        INNER JOIN PAYMENTS p2
            ON o2.ORDER_ID = p2.ORDER_ID
        GROUP BY c2.CUSTOMER_UNIQUE_ID
    ) AS CUSTOMER_TOTALS
)ORDER BY TOTAL_SPENDING DESC;
     
-- Q12. Find customers who have placed more orders than the average number of orders placed by a customer.

SELECT 
	c.CUSTOMER_UNIQUE_ID , 
    COUNT(o.ORDER_ID) AS ORDER_COUNT 
FROM CUSTOMERS c
INNER JOIN ORDERS o 
	ON c.CUSTOMER_ID = o.CUSTOMER_ID
GROUP BY c.CUSTOMER_UNIQUE_ID
HAVING COUNT(o.ORDER_ID) > (
	SELECT AVG(ORDER_COUNT) AS AVG_ORDER_COUNT 
	FROM (
		SELECT c1.CUSTOMER_UNIQUE_ID , COUNT(o1.ORDER_ID) AS ORDER_COUNT 
		FROM CUSTOMERS c1
		INNER JOIN ORDERS o1 
			ON c1.CUSTOMER_ID = o1.CUSTOMER_ID
		GROUP BY c1.CUSTOMER_UNIQUE_ID
	) AS CUSTOMER_AVG_COUNT 
) ORDER BY ORDER_COUNT DESC;


-- Q13 Find customers who have never placed a delivered order.
-- Use NOT EXISTS to identify customers without any delivered orders.

SELECT
    c.CUSTOMER_UNIQUE_ID,
    c.CUSTOMER_CITY
FROM CUSTOMERS c
WHERE NOT EXISTS (
    SELECT 1
    FROM ORDERS o
    WHERE c.CUSTOMER_ID = o.CUSTOMER_ID
      AND o.ORDER_STATUS = 'DELIVERED'
);
 
 -- Q14 Find the average spending of customers, and then find customers whose total spending is above that average
-- Use CTEs to calculate customer spending, the average spending, and identify above-average customers.

WITH SPENDING AS (
    SELECT
        c.CUSTOMER_UNIQUE_ID,
        SUM(p.PAYMENT_VALUE) AS TOTAL_SPENDING
    FROM CUSTOMERS c
    INNER JOIN ORDERS o
        ON c.CUSTOMER_ID = o.CUSTOMER_ID
    INNER JOIN PAYMENTS p
        ON o.ORDER_ID = p.ORDER_ID
    GROUP BY c.CUSTOMER_UNIQUE_ID
),

AVG_SPENDING AS (
    SELECT
        AVG(TOTAL_SPENDING) AS AVG_SPENDING
    FROM SPENDING
)

SELECT
    s.CUSTOMER_UNIQUE_ID,
    s.TOTAL_SPENDING,
    a.AVG_SPENDING
FROM SPENDING s
CROSS JOIN AVG_SPENDING a
WHERE s.TOTAL_SPENDING > a.AVG_SPENDING
ORDER BY s.TOTAL_SPENDING DESC;

-- Q15 For each customer, show their orders along with the previous order's purchase date.
-- Use LAG() to compare each order with the customer's previous order.

SELECT
    c.CUSTOMER_UNIQUE_ID,
    o.ORDER_ID,
    o.ORDER_PURCHASE_TIMESTAMP,
    LAG(o.ORDER_PURCHASE_TIMESTAMP) OVER (
        PARTITION BY c.CUSTOMER_UNIQUE_ID
        ORDER BY o.ORDER_PURCHASE_TIMESTAMP
    ) AS PREVIOUS_PURCHASE_DATE
FROM CUSTOMERS c
INNER JOIN ORDERS o
    ON c.CUSTOMER_ID = o.CUSTOMER_ID
ORDER BY
    c.CUSTOMER_UNIQUE_ID,
    o.ORDER_PURCHASE_TIMESTAMP;
    
    
-- Q16 Find customers who have placed at least 2 orders, and for each of their orders show:
-- the payment value, previous order's payment value, and the change from the previous order.
-- Use window functions to compare each customer's order payments over time.

WITH ORDER_PAYMENTS AS (
    SELECT
        c.CUSTOMER_UNIQUE_ID,
        o.ORDER_ID,
        o.ORDER_PURCHASE_TIMESTAMP,
        SUM(p.PAYMENT_VALUE) AS PAYMENT_VALUE
    FROM CUSTOMERS c
    INNER JOIN ORDERS o
        ON c.CUSTOMER_ID = o.CUSTOMER_ID
    INNER JOIN PAYMENTS p
        ON o.ORDER_ID = p.ORDER_ID
    GROUP BY
        c.CUSTOMER_UNIQUE_ID,
        o.ORDER_ID,
        o.ORDER_PURCHASE_TIMESTAMP
),

PAYMENT_HISTORY AS (
    SELECT
        CUSTOMER_UNIQUE_ID,
        ORDER_ID,
        COUNT(ORDER_ID) OVER (
            PARTITION BY CUSTOMER_UNIQUE_ID
        ) AS ORDER_COUNT,
        ORDER_PURCHASE_TIMESTAMP,
        PAYMENT_VALUE,
        LAG(PAYMENT_VALUE) OVER (
            PARTITION BY CUSTOMER_UNIQUE_ID
            ORDER BY ORDER_PURCHASE_TIMESTAMP
        ) AS PREVIOUS_PAYMENT_VALUE
    FROM ORDER_PAYMENTS
)

SELECT
    CUSTOMER_UNIQUE_ID,
    ORDER_ID,
    ORDER_COUNT,
    ORDER_PURCHASE_TIMESTAMP,
    PAYMENT_VALUE,
    PREVIOUS_PAYMENT_VALUE,
    PAYMENT_VALUE - PREVIOUS_PAYMENT_VALUE AS CHANGE_FROM_PREV
FROM PAYMENT_HISTORY
WHERE ORDER_COUNT >= 2
ORDER BY
    CUSTOMER_UNIQUE_ID,
    ORDER_PURCHASE_TIMESTAMP;

-- Q17 Identify customers whose spending increased on every subsequent order.
-- Compare each customer's order spending with their previous order and
-- keep customers who never had a decrease or equal spending.

WITH CURRENT_PAYMENTS AS (
    SELECT
        c.CUSTOMER_UNIQUE_ID,
        o.ORDER_ID,
        o.ORDER_PURCHASE_TIMESTAMP,
        SUM(p.PAYMENT_VALUE) AS CURRENT_PAYMENT
    FROM CUSTOMERS c
    INNER JOIN ORDERS o
        ON c.CUSTOMER_ID = o.CUSTOMER_ID
    INNER JOIN PAYMENTS p
        ON o.ORDER_ID = p.ORDER_ID
    GROUP BY
        c.CUSTOMER_UNIQUE_ID,
        o.ORDER_ID,
        o.ORDER_PURCHASE_TIMESTAMP
),

PAYMENT_STATUS AS (
    SELECT
        CUSTOMER_UNIQUE_ID,
        ORDER_ID,
        ORDER_PURCHASE_TIMESTAMP,
        CURRENT_PAYMENT,
        LAG(CURRENT_PAYMENT) OVER (
            PARTITION BY CUSTOMER_UNIQUE_ID
            ORDER BY ORDER_PURCHASE_TIMESTAMP
        ) AS PREVIOUS_PAYMENT
    FROM CURRENT_PAYMENTS
),

CUSTOMER_CHECK AS (
    SELECT
        CUSTOMER_UNIQUE_ID,
        SUM(
            CASE
                WHEN PREVIOUS_PAYMENT IS NOT NULL
                     AND CURRENT_PAYMENT <= PREVIOUS_PAYMENT
                THEN 1
                ELSE 0
            END
        ) AS FAILED_ORDERS
    FROM PAYMENT_STATUS
    GROUP BY CUSTOMER_UNIQUE_ID
	HAVING COUNT(*) >= 2
)

SELECT
    CUSTOMER_UNIQUE_ID
FROM CUSTOMER_CHECK
WHERE FAILED_ORDERS = 0
;   

-- Q18 Find the top 3 customers in each state based on their total payment spending.
-- Rank customers within each state based on their total spending.

WITH SPENDING_BY_STATE AS (
    SELECT
        c.CUSTOMER_UNIQUE_ID,
        c.CUSTOMER_STATE,
        c.CUSTOMER_CITY,
        SUM(p.PAYMENT_VALUE) AS TOTAL_SPENDING
    FROM CUSTOMERS c
    INNER JOIN ORDERS o
        ON c.CUSTOMER_ID = o.CUSTOMER_ID
    INNER JOIN PAYMENTS p
        ON o.ORDER_ID = p.ORDER_ID
    GROUP BY
        c.CUSTOMER_STATE,
        c.CUSTOMER_UNIQUE_ID,
        c.CUSTOMER_CITY
),

CUST_RNK AS (
    SELECT
        CUSTOMER_UNIQUE_ID,
        CUSTOMER_STATE,
        CUSTOMER_CITY,
        TOTAL_SPENDING,
        ROW_NUMBER() OVER (
            PARTITION BY CUSTOMER_STATE
            ORDER BY TOTAL_SPENDING DESC
        ) AS RNK
    FROM SPENDING_BY_STATE
)

SELECT
    CUSTOMER_UNIQUE_ID,
    CUSTOMER_STATE,
    CUSTOMER_CITY,
    TOTAL_SPENDING,
    RNK
FROM CUST_RNK
WHERE RNK <= 3
ORDER BY
    CUSTOMER_STATE,
    RNK;

-- Q19. How can we handle missing or blank review comments?
-- Replace NULL and blank review comments with "NO COMMENT".

SELECT
    REVIEW_ID,
    REVIEW_COMMENT_MESSAGE,
    COALESCE(
        NULLIF(TRIM(REVIEW_COMMENT_MESSAGE), ''),
        'NO COMMENT'
    ) AS REVIEW_COMMENT_STATUS
FROM REVIEWS;

-- Q 20 Show each order's purchase date and payment value, along with the cumulative payment value over time.
-- Calculate the cumulative payment value based on the order purchase date.

WITH ORDER_PAYMENTS AS (
    SELECT
        o.ORDER_ID,
        o.ORDER_PURCHASE_TIMESTAMP,
        SUM(p.PAYMENT_VALUE) AS PAYMENT_VALUE
    FROM ORDERS o
    INNER JOIN PAYMENTS p
        ON o.ORDER_ID = p.ORDER_ID
    GROUP BY
        o.ORDER_ID,
        o.ORDER_PURCHASE_TIMESTAMP
)

SELECT
    ORDER_ID,
    ORDER_PURCHASE_TIMESTAMP,
    PAYMENT_VALUE,
    SUM(PAYMENT_VALUE) OVER (
        ORDER BY ORDER_PURCHASE_TIMESTAMP, ORDER_ID
        ROWS UNBOUNDED PRECEDING
    ) AS CUMULATIVE_PAYMENT
FROM ORDER_PAYMENTS
ORDER BY
    ORDER_PURCHASE_TIMESTAMP,
    ORDER_ID;
    


-- ============================================================================
-- 3. PRODUCT & CATEGORY PERFORMANCE
-- ============================================================================
-- Analyze product and category sales, revenue, rankings, and performance.   

 
    
-- Q21. What are the top 10 product categories by number of products sold?
-- Identify the product categories with the highest number of products sold.

SELECT
    p.PRODUCT_CATEGORY_NAME,
    COUNT(*) AS PRODUCTS_SOLD
FROM PRODUCTS p
INNER JOIN ORDER_ITEMS oi
    ON p.PRODUCT_ID = oi.PRODUCT_ID
GROUP BY p.PRODUCT_CATEGORY_NAME
ORDER BY PRODUCTS_SOLD DESC
LIMIT 10;

-- Q22 Which 10 product categories generate the highest total sales revenue?

SELECT 
    p.PRODUCT_CATEGORY_NAME, 
    SUM(oi.PRICE) AS TOTAL_REVENUE
FROM
    PRODUCTS p
        INNER JOIN
    ORDER_ITEMS oi ON 
    p.PRODUCT_ID = oi.PRODUCT_ID
GROUP BY p.PRODUCT_CATEGORY_NAME
ORDER BY TOTAL_REVENUE DESC
LIMIT 10;

-- Q23. What is the total revenue generated by each product category from orders where the order status is delivered?

SELECT 
    p.PRODUCT_CATEGORY_NAME,
    SUM(oi.PRICE) AS TOTAL_REVENUE
FROM
    PRODUCTS p
        INNER JOIN
    ORDER_ITEMS oi ON 
    p.PRODUCT_ID = oi.PRODUCT_ID
    INNER JOIN ORDERS o ON
    oi.ORDER_ID = o.ORDER_ID
    WHERE o.ORDER_STATUS = 'DELIVERED'
    
GROUP BY p.PRODUCT_CATEGORY_NAME
ORDER BY TOTAL_REVENUE DESC;

-- Q24. For each product category, classify its total revenue

SELECT p.PRODUCT_CATEGORY_NAME , 
pc.PRODUCT_CATEGORY_NAME_ENGLISH,
SUM(oi.PRICE) AS TOTAL_REVENUE,
CASE
	WHEN SUM(oi.PRICE) >= 500000 THEN "HIGH REVENUE"
    WHEN SUM(oi.PRICE) >= 100000 THEN "MEDIUM REVENUE"
    ELSE "LOW REVENUE"
    END AS REV_CATEGORY
FROM PRODUCTS p
INNER JOIN ORDER_ITEMS oi
	ON p.PRODUCT_ID = oi.PRODUCT_ID 
INNER JOIN PRODUCT_CATEGORY_NAME pc 
	ON p.PRODUCT_CATEGORY_NAME = pc.PRODUCT_CATEGORY_NAME
GROUP BY 
	p.PRODUCT_CATEGORY_NAME ,
    pc.PRODUCT_CATEGORY_NAME_ENGLISH
ORDER BY TOTAL_REVENUE  DESC;

-- Q25 Find all products whose total sales revenue is greater than the average total sales revenue per product.
-- Compare each product's total sales revenue with the average product revenue.

SELECT 
	p.PRODUCT_ID, 
    p.PRODUCT_CATEGORY_NAME , 
    SUM(oi.PRICE) AS TOTAL_SALES_REVENUE
FROM PRODUCTS p
INNER JOIN ORDER_ITEMS oi 
	ON p.PRODUCT_ID = oi.PRODUCT_ID
GROUP BY 
	p.PRODUCT_ID, 
    p.PRODUCT_CATEGORY_NAME
HAVING SUM(oi.PRICE) > (
	SELECT AVG(TOTAL_SALES_REVENUE)
	FROM 
		(
			SELECT p1.PRODUCT_ID, 
			p1.PRODUCT_CATEGORY_NAME , 
            SUM(oi1.PRICE) AS TOTAL_SALES_REVENUE
			FROM PRODUCTS p1
			INNER JOIN ORDER_ITEMS oi1 
				ON p1.PRODUCT_ID = oi1.PRODUCT_ID
			GROUP BY 
				p1.PRODUCT_CATEGORY_NAME , 
                p1.PRODUCT_ID
		)AS AVG_SALES
) 
ORDER BY TOTAL_SALES_REVENUE DESC ;
 


-- Q26 For each product category, rank the products by their total sales revenue, highest revenue = Rank 1.
-- Rank products within each category based on their total sales revenue.

SELECT
    p.PRODUCT_ID,
    COALESCE(
        NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
        'UNKNOWN'
    ) AS PRODUCT_CATEGORY,
    SUM(oi.PRICE) AS REVENUE,
    RANK() OVER (
        PARTITION BY COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
        )
        ORDER BY SUM(oi.PRICE) DESC
    ) AS REVENUE_RANK
FROM PRODUCTS p
INNER JOIN ORDER_ITEMS oi
    ON p.PRODUCT_ID = oi.PRODUCT_ID
GROUP BY
    p.PRODUCT_ID,
    p.PRODUCT_CATEGORY_NAME
ORDER BY
    PRODUCT_CATEGORY,
    REVENUE_RANK;


-- Q27 For each product category, find the top 3 products by total revenue.
-- Rank products within each category and return the top 3 products.

WITH PRODUCT_REVENUE AS (
    SELECT
        p.PRODUCT_ID,
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
        ) AS PRODUCT_CATEGORY,
        SUM(oi.PRICE) AS TOTAL_REVENUE
    FROM PRODUCTS p
    INNER JOIN ORDER_ITEMS oi
        ON p.PRODUCT_ID = oi.PRODUCT_ID
    GROUP BY
        p.PRODUCT_ID,
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
        )
),

RANKED_PRODUCT AS (
    SELECT
        PRODUCT_CATEGORY,
        PRODUCT_ID,
        TOTAL_REVENUE,
        ROW_NUMBER() OVER (
            PARTITION BY PRODUCT_CATEGORY
            ORDER BY TOTAL_REVENUE DESC
        ) AS REVENUE_RANK
    FROM PRODUCT_REVENUE
)

SELECT
    PRODUCT_ID,
    PRODUCT_CATEGORY,
    TOTAL_REVENUE,
    REVENUE_RANK
FROM RANKED_PRODUCT
WHERE REVENUE_RANK <= 3
ORDER BY
    PRODUCT_CATEGORY,
    REVENUE_RANK;

-- Q28 For each product category, show each product's total revenue along with the average product revenue within that category.
-- Use a window function to compare each product's revenue with the category-level average.

WITH PRODUCT_REVENUE AS (
    SELECT
        p.PRODUCT_ID,
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
        ) AS PRODUCT_CATEGORY,
        SUM(oi.PRICE) AS TOTAL_REVENUE
    FROM PRODUCTS p
    INNER JOIN ORDER_ITEMS oi
        ON p.PRODUCT_ID = oi.PRODUCT_ID
    GROUP BY
        p.PRODUCT_ID,
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
        )
)

SELECT
    PRODUCT_ID,
    PRODUCT_CATEGORY,
    TOTAL_REVENUE,
    AVG(TOTAL_REVENUE) OVER (
        PARTITION BY PRODUCT_CATEGORY
    ) AS AVG_REVENUE
FROM PRODUCT_REVENUE
ORDER BY
    PRODUCT_CATEGORY,
    TOTAL_REVENUE DESC;
    
-- Q29 For each product category, show each product's revenue and the cumulative revenue within that category, ordered from lowest to highest product revenue.
-- Calculate cumulative revenue for each category based on product revenue.

WITH PRODUCT_REVENUE AS (
    SELECT
        p.PRODUCT_ID,
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
        ) AS PRODUCT_CATEGORY,
        SUM(oi.PRICE) AS REVENUE
    FROM PRODUCTS p
    INNER JOIN ORDER_ITEMS oi
        ON p.PRODUCT_ID = oi.PRODUCT_ID
    GROUP BY
        p.PRODUCT_ID,
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN')
)

SELECT
    PRODUCT_ID,
    PRODUCT_CATEGORY,
    REVENUE,
    SUM(REVENUE) OVER (
        PARTITION BY PRODUCT_CATEGORY
        ORDER BY REVENUE, PRODUCT_ID
        ROWS UNBOUNDED PRECEDING
    ) AS CUMULATIVE_REVENUE
FROM PRODUCT_REVENUE
ORDER BY
    PRODUCT_CATEGORY,
    REVENUE;



-- ============================================================================
-- 4. DELIVERY PERFORMANCE
-- ============================================================================
-- Analyze delivery time, late deliveries, and delivery performance trends.



-- Q30. For each order status, show how many orders have a delivery date and how many don't.
-- Compare orders with and without a customer delivery date across each order status.

SELECT
    ORDER_STATUS,
    COUNT(ORDER_DELIVERED_CUSTOMER_DATE) AS ORDERS_WITH_DELIVERY_DATE,
    COUNT(*) - COUNT(ORDER_DELIVERED_CUSTOMER_DATE) AS ORDERS_WITHOUT_DELIVERY_DATE
FROM ORDERS
GROUP BY ORDER_STATUS
ORDER BY ORDER_STATUS;

-- Q31. For each delivered order, calculate how many days it took from purchase to customer delivery.
-- Calculate the delivery duration in days for delivered orders.

SELECT
    ORDER_ID,
    DATEDIFF(
        ORDER_DELIVERED_CUSTOMER_DATE,
        ORDER_PURCHASE_TIMESTAMP
    ) AS DELIVERY_DAYS
FROM ORDERS
WHERE ORDER_STATUS = 'DELIVERED';

-- Q32 For each month of 2018, calculate the average delivery time (in days) for delivered orders.
-- Calculate the average delivery duration for each month in chronological order.

SELECT
    MONTHNAME(ORDER_PURCHASE_TIMESTAMP) AS ORDER_MONTH,
    ROUND(
        AVG(
            DATEDIFF(
                ORDER_DELIVERED_CUSTOMER_DATE,
                ORDER_PURCHASE_TIMESTAMP
            )
        ),2) AS AVG_DELIVERY_DAYS
FROM ORDERS
WHERE YEAR(ORDER_PURCHASE_TIMESTAMP) = 2018
  AND ORDER_STATUS = 'DELIVERED'
GROUP BY
    MONTH(ORDER_PURCHASE_TIMESTAMP),
    MONTHNAME(ORDER_PURCHASE_TIMESTAMP)
ORDER BY
    MONTH(ORDER_PURCHASE_TIMESTAMP);

-- Q33.  For delivered orders, classify each order as LATE or ON TIME by comparing the actual delivery date with the estimated delivery date.
-- Identify whether each delivered order arrived late or on time.

SELECT
    ORDER_ID,
    ORDER_DELIVERED_CUSTOMER_DATE,
    ORDER_ESTIMATED_DELIVERY_DATE,
CASE
        WHEN ORDER_DELIVERED_CUSTOMER_DATE > ORDER_ESTIMATED_DELIVERY_DATE
            THEN 'LATE'
        ELSE 'ON TIME'
    END AS DELIVERY_STATUS
FROM ORDERS
WHERE ORDER_STATUS = 'DELIVERED';

-- Q34. For each month of 2018, among delivered orders, how many were late and how many were on time?
-- Compare monthly delivered orders based on their actual delivery date.

SELECT  
	MONTH(order_delivered_customer_date) AS MONTH_NUM,
    MONTHNAME(order_delivered_customer_date) AS DELIVERY_MONTH,
    COUNT(*) AS DELIVERED_ORDERS ,
    SUM(
		CASE
			WHEN (order_delivered_customer_date > order_estimated_delivery_date ) THEN 1
			ELSE 0 
		END) AS LATE_ORDERS,
	SUM(
		CASE
			WHEN (order_delivered_customer_date <= order_estimated_delivery_date ) THEN 1
			ELSE 0
    END) AS ON_TIME_ORDERS
FROM ORDERS 
WHERE ORDER_STATUS = "DELIVERED"
	AND YEAR (order_delivered_customer_date) = 2018
GROUP BY  
	DELIVERY_MONTH, 
    MONTH_NUM
ORDER BY MONTH_NUM;

-- Q35. For each product category, find the percentage of its orders that were delivered late.
-- Calculate the percentage of delivered orders that arrived after the estimated delivery date.

WITH DELIVERED_ORDER_COUNT AS (
SELECT
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN'
				) AS PRODUCT_CATEGORY_NAME,
        COUNT(DISTINCT o.ORDER_ID) AS TOTAL_ORDERS,
        COUNT(
            DISTINCT CASE
                WHEN o.ORDER_DELIVERED_CUSTOMER_DATE > o.ORDER_ESTIMATED_DELIVERY_DATE
                THEN o.ORDER_ID
			END ) AS LATE_DELIVERED_ORDERS
	FROM PRODUCTS p
    INNER JOIN ORDER_ITEMS oi
        ON p.PRODUCT_ID = oi.PRODUCT_ID
    INNER JOIN ORDERS o
        ON oi.ORDER_ID = o.ORDER_ID
    WHERE o.ORDER_STATUS = 'DELIVERED'
    GROUP BY
        COALESCE(
            NULLIF(p.PRODUCT_CATEGORY_NAME, ''),
            'UNKNOWN')
            ),

LATE_DELIVERY_PERCENT AS (
    SELECT
        PRODUCT_CATEGORY_NAME,
        TOTAL_ORDERS,
        LATE_DELIVERED_ORDERS,
        ROUND(
            (LATE_DELIVERED_ORDERS / TOTAL_ORDERS) * 100,2) AS LATE_DELIVERY_PERCENT
    FROM DELIVERED_ORDER_COUNT)
    
    SELECT
    PRODUCT_CATEGORY_NAME,
    TOTAL_ORDERS,
    LATE_DELIVERED_ORDERS,
    LATE_DELIVERY_PERCENT
FROM LATE_DELIVERY_PERCENT
ORDER BY LATE_DELIVERY_PERCENT DESC ;



-- ============================================================================
-- 5. SELLER PERFORMANCE
-- ============================================================================
-- Analyze seller revenue, product performance, and seller-level sales behavior.



-- Q36 Find the sellers who generated above-average revenue,
-- but only among sellers who sold at least 10 distinct products.
-- Compare qualifying sellers against the average revenue of qualifying sellers.

WITH SELLER_REVENUE AS (
    SELECT
        s.SELLER_ID,
        COUNT(DISTINCT p.PRODUCT_ID) AS DISTINCT_PRODUCT_COUNT,
        SUM(oi.PRICE) AS TOTAL_REVENUE
    FROM SELLERS s
    INNER JOIN ORDER_ITEMS oi
        ON s.SELLER_ID = oi.SELLER_ID
    INNER JOIN PRODUCTS p
        ON oi.PRODUCT_ID = p.PRODUCT_ID
    GROUP BY
        s.SELLER_ID
),

QUALIFYING_SELLERS AS (
    SELECT
        SELLER_ID,
        DISTINCT_PRODUCT_COUNT,
        TOTAL_REVENUE
    FROM SELLER_REVENUE
    WHERE DISTINCT_PRODUCT_COUNT >= 10
)

SELECT
    SELLER_ID,
    DISTINCT_PRODUCT_COUNT,
    TOTAL_REVENUE
FROM QUALIFYING_SELLERS
WHERE TOTAL_REVENUE > (
    SELECT AVG(TOTAL_REVENUE)
    FROM QUALIFYING_SELLERS
)
ORDER BY TOTAL_REVENUE DESC;    
    