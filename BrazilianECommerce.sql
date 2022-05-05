--1. Customer satisfaction: count and % of Orders purchased with 5 Review score
-- by year_month
WITH review_by_yearmonth AS (
				SELECT 
					FORMAT(review_answer_timestamp, 'yyyy-MM') AS year_month,
					SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) AS count_score5,
					COUNT(DISTINCT r.order_id) AS total_order
				FROM reviews AS r
				LEFT JOIN orders AS o
				ON r.order_id = o.order_id
				WHERE order_status = 'delivered'
				GROUP BY FORMAT(review_answer_timestamp, 'yyyy-MM')
)
SELECT 
	year_month,
	count_score5,
	total_order,
	CONCAT(ROUND(CAST(count_score5 AS float)/CAST(total_order AS float) * 100, 2), '%') AS percentage
FROM review_by_yearmonth;

-- by year
WITH review_by_year AS (
				SELECT 
					YEAR(review_answer_timestamp) AS year_review,
					SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) AS count_score5,
					COUNT(DISTINCT r.order_id) AS total_order
				FROM reviews AS r
				LEFT JOIN orders AS o
				ON r.order_id = o.order_id
				WHERE order_status = 'delivered'
				GROUP BY YEAR(review_answer_timestamp)
)
SELECT 
	year_review,
	count_score5,
	total_order,
	CONCAT(ROUND(CAST(count_score5 AS float)/CAST(total_order AS float) * 100, 2), '%') AS percentage
FROM review_by_year;

--2. purchase trend
SELECT 
	MONTH(order_purchase_timestamp) AS month_order,
	SUM(CASE WHEN YEAR(order_purchase_timestamp) = 2016 THEN 1 ELSE 0 END) AS Y2016,
	SUM(CASE WHEN YEAR(order_purchase_timestamp) = 2017 THEN 1 ELSE 0 END) AS Y2017,
	SUM(CASE WHEN YEAR(order_purchase_timestamp) = 2018 THEN 1 ELSE 0 END) AS Y2018
FROM orders
WHERE order_status <> 'canceled' AND order_status <> 'unavailable'
GROUP BY MONTH(order_purchase_timestamp)
ORDER BY month_order;

--the number of purchase by year
SELECT 
	YEAR(order_purchase_timestamp) AS year_order,
	COUNT(DISTINCT order_id) AS number_order
FROM orders
WHERE order_status <> 'canceled' AND order_status <> 'unavailable'
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY year_order;

--3. payment: Aggregation of customer payment method

SELECT 
	payment_type,
	COUNT(p.order_id) AS number_order_per_type,
	ROUND(SUM(payment_value), 2) AS total_value_per_type
FROM payments AS p
LEFT JOIN orders AS o
ON p.order_id = o.order_id
WHERE order_delivered_customer_date IS NOT NULL AND order_status <> 'canceled'
GROUP BY payment_type
ORDER BY number_order_per_type DESC;

--4. product category: Top 10 and bottom 10 product categories by revenue.
--bottom 10 product categories by revenue
WITH low_revenue AS (
					SELECT product_category_name_english AS category,
					COUNT(payments.order_id) AS number_order,
					ROUND(SUM(payment_value), 2) AS revenue
					FROM products
					LEFT JOIN order_items AS item
					ON products.product_id = item.product_id
					LEFT JOIN orders
					ON item.order_id = orders.order_id
					LEFT JOIN payments
					ON payments.order_id = orders.order_id
					LEFT JOIN english_product_name AS product_name
					ON product_name.product_category_name = products.product_category_name
					WHERE order_status <> 'canceled'
						AND order_delivered_customer_date IS NOT NULL
						AND products.product_category_name IS NOT NULL
					GROUP BY product_category_name_english
)
SELECT TOP 10
	category,
	number_order,
	revenue
FROM low_revenue
ORDER BY revenue;

--top 10 product categories by revenue
WITH high_revenue AS (
					SELECT product_category_name_english AS category,
					COUNT(payments.order_id) AS number_order,
					ROUND(SUM(payment_value), 2) AS revenue
					FROM products
					LEFT JOIN order_items AS item
					ON products.product_id = item.product_id
					LEFT JOIN orders
					ON item.order_id = orders.order_id
					LEFT JOIN payments
					ON payments.order_id = orders.order_id
					LEFT JOIN english_product_name AS product_name
					ON product_name.product_category_name = products.product_category_name
					WHERE order_status <> 'canceled'
						AND order_delivered_customer_date IS NOT NULL
						AND products.product_category_name IS NOT NULL
					GROUP BY product_category_name_english
)
SELECT TOP 10
	category,
	number_order,
	revenue
FROM high_revenue
ORDER BY revenue DESC;

--5. sellers: Aggregation of revenue as per products categories and sellers

SELECT product_category_name_english AS category,
ROW_NUMBER() OVER (PARTITION BY product_category_name_english ORDER BY SUM(payment_value) DESC) AS STT,
sellers.seller_id,
ROUND(SUM(payment_value), 2) AS revenue
FROM products
LEFT JOIN english_product_name AS product_name
ON product_name.product_category_name = products.product_category_name
LEFT JOIN order_items AS item
ON products.product_id = item.product_id
LEFT JOIN orders
ON item.order_id = orders.order_id
LEFT JOIN payments
ON payments.order_id = orders.order_id
LEFT JOIN sellers
ON item.seller_id = sellers.seller_id
WHERE order_status <> 'canceled'
AND order_delivered_customer_date IS NOT NULL
AND product_category_name_english IS NOT NULL
GROUP BY product_category_name_english, sellers.seller_id;

--6. state
-- Aggregation of revenue by 'state'
SELECT customer_state,
ROUND(SUM(payment_value), 2) AS revenue
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id
LEFT JOIN payments
ON orders.order_id = payments.order_id
WHERE order_status <> 'canceled'
AND order_delivered_customer_date IS NOT NULL
GROUP BY customer_state
ORDER BY revenue DESC;

--Top 5 product categories by 'state'
SELECT TOP 5 product_category_name_english AS category,
ROUND(SUM(payment_value), 2) AS revenue,
customer_state
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id
LEFT JOIN payments
ON orders.order_id = payments.order_id
LEFT JOIN order_items AS item
ON item.order_id = orders.order_id
LEFT JOIN products
ON item.product_id = products.product_id
LEFT JOIN english_product_name AS product_name
ON products.product_category_name = product_name.product_category_name
WHERE order_status <> 'canceled'
AND order_delivered_customer_date IS NOT NULL
AND products.product_category_name IS NOT NULL
GROUP BY customer_state, product_category_name_english
ORDER BY revenue DESC;

--Number of customers & sellers by 'state'
WITH table1 AS (
SELECT 
	customer_state AS state,
	COUNT(customer_id) AS number_customer
FROM customers
GROUP BY customer_state
),
table2 AS (
SELECT 
	seller_state AS state,
	COUNT(seller_id) AS number_seller
FROM sellers
GROUP BY seller_state
)
SELECT table1.state, number_customer, number_seller
FROM table1
LEFT JOIN table2
ON table1.state = table2.state
ORDER BY number_customer DESC;

--7. delivery by state: Date difference between 'order_approved_at' and 'order_estimated_delivery_date' by 'State'

SELECT customer_state,
AVG(DATEDIFF(day, FORMAT(order_approved_at,'yyyy-MM-dd'), FORMAT(order_estimated_delivery_date, 'yyyy-MM-dd'))) AS avg_datediff
FROM orders
LEFT JOIN customers
ON orders.customer_id = customers.customer_id
WHERE order_approved_at IS NOT NULL
GROUP BY customer_state
ORDER BY avg_datediff;