USE ecommerce_analytics;

-- =====================================================
-- E-COMMERCE ANALYTICS PORTFOLIO PROJECT
-- =====================================================
-- Purpose:
-- Analyze customer purchasing behavior, customer segments,
-- and product/category performance using MySQL.
--
-- Sections:
-- 1. Customer Analysis
-- 2. Customer Segmentation (RFM)
-- 3. Product & Category Analysis
--
-- Tools: MySQL Workbench, MySQL
--
-- Notes:
-- Analysis queries only. Database setup and data loading
-- are maintained in a separate SQL file.


-- =====================================================
-- SECTIon 1: CUSTOMER ANALYSIS
-- =====================================================


SELECT 'customers' as table_name, COUNT(*) as row_count
FROM customers

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'categories', COUNT(*)
FROM categories

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM payments;

-- Data Exploration & Quality:

-- 1- How many customers in each region?

SELECT 
region,
COUNT(customer_id) AS customer_count 
FROM customers 
GROUP BY region 
ORDER BY customer_count DESC;

-- 2- How many orders are there for each status?

SELECT 
status, 
	count(order_id) AS order_count
FROM orders
GROUP BY status;

-- 3- What is the earliest and latest order date?

SELECT MIN(order_date) AS earliest_order,
MAX(order_date) AS latest_order FROM orders;

-- 4- . What are the different payment methods and how many payments use each one?

SELECT payment_method, 
COUNT(payment_id) AS payment_count FROM payments
 GROUP BY 
 payment_method 
 ORDER BY payment_count DESC ;

-- 5- Total payment amount.

SELECT SUM(amount) AS total_payments 
FROM payments;

-- 6- Average payment amount.

SELECT AVG(amount) AS Average_payment_amount 
FROM payments;

-- 7- Average number of items per order.

SELECT 
SUM(quantity)/COUNT(DISTINCT order_id) AS avg_items_per_order 
FROM order_items;

-- 8- Which customers have placed the most orders?

SELECT 
c.customer_id,
c.name,
COUNT(o.order_id) order_count
FROM customers c LEFT JOIN orders o 
ON c.customer_id=o.customer_id
GROUP BY c.customer_id,c.name
ORDER BY order_count DESC;

-- 9- Which 10 customers have generated the highest total payment amount?

SELECT 
c.customer_id,
c.name,
SUM(p.amount) AS total_amount 
FROM customers c 
LEFT JOIN 
orders o 
ON 
c.customer_id=o.customer_id 
JOIN payments p 
ON 
p.order_id = o.order_id
GROUP BY 
c.customer_id,c.name
ORDER BY total_amount DESC 
LIMIT 10;

-- 10- What percentage of the company's total payments came FROM each of the top 10 customers?

WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.name,
        COALESCE(SUM(p.amount), 0) AS total_spent
    FROM customers c
    JOIN orders o 
       ON c.customer_id = o.customer_id
    JOIN payments p 
       ON o.order_id = p.order_id
    GROUP BY c.customer_id, c.name
)

SELECT
    customer_id,
    name,
    total_spent,
    ROUND(
        total_spent / (SELECT SUM(amount) FROM payments) * 100,
        2
    ) AS percentage_of_total
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 10;

-- 11- How much revenue did the business generate each month?

SELECT  
DATE_FORMAT(payment_date,'%Y-%m') as month,
 SUM(amount) as total_revenue 
 FROM payments 
 GROUP BY month 
 ORDER BY month;
 
 -- 12- Calculate monthly revenue AND the previous month's revenue in the same result.
 
with monthly_revenue as(SELECT  
DATE_FORMAT(payment_date,'%Y-%m') as month,
 SUM(amount) as total_revenue 
 FROM payments 
 GROUP BY month)
 SELECT month,total_revenue,LAG(total_revenue) OVER (ORDER BY month) as previous_month_revenue FROM monthly_revenue;
 
 -- 13- What was the month-over-month percentage change in revenue?

WITH monthly_revenue as
(SELECT  
date_format(payment_date,'%Y-%m') as month,
 SUM(amount) as total_revenue 
 FROM payments 
 GROUP BY month),
 lag_value as 
 (SELECT month,
 total_revenue,
 LAG(total_revenue) OVER (ORDER BY month) as previous_month_revenue 
 FROM monthly_revenue)
 SELECT 
 month,
 total_revenue,
 previous_month_revenue,
 ROUND((total_revenue - previous_month_revenue)/NULLIF(previous_month_revenue,0) * 100,2) 
 as percentage_change 
 FROM 
 lag_value;

-- 14- For each customer, find their first order date and most recent order date.

SELECT 
c.customer_id,
c.name,
min(o.order_date) as first_order_date,
max(o.order_date) as latest_order_date 
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY 
c.customer_id,c.name;

-- 15- Calculate the total amount each customer has spent, along with their first and latest order dates.

SELECT 
c.customer_id,
c.name,
min(o.order_date) as first_order_date,
max(o.order_date) as latest_order_date, 
SUM(p.amount) as amount_spent 
FROM customers c 
LEFT JOIN 
orders o 
on
c.customer_id =o.customer_id 
LEFT JOIN 
payments p 
on 
p.order_id=o.order_id
GROUP BY 
c.name,c.customer_id;


--  Customer Segmentation:

with total_spent as 
(SELECT c.customer_id,
c.name,
coalesce(SUM(p.amount),0) as total_spent 
FROM customers c LEFT JOIN orders o 
on 
c.customer_id = o.customer_id 
LEFT JOIN 
payments p 
on 
p.order_id=o.order_id 
GROUP BY c.customer_id,c.name)
SELECT customer_id,name,total_spent, case
when total_spent <=500 then "low value"
when total_spent <=1500 then "medium value"
when total_spent >1500 then "High value" end 
as customer_category 
FROM total_spent ORDER BY total_spent DESC;


-- =====================================================
-- SECTIon 2: CUSTOMER SEGMENTATIon (RFM)
-- =====================================================

-- RFM Style customer Analysis 
-- RECENCY (DAYS SINCE LasT ORDER)
-- FREQUENCY (COUNT)
-- MonETARY (TOTAL SPENT)

-- For each customer, calculate:
-- Last order date → MAX(order_date), Order count → COUNT(order_id), Total spent → SUM(payment amount)

with last_order as(SELECT 
c.customer_id,
c.name, 
max(o.order_date) as last_order_date, 
count(distinct o.order_id) as order_count, 
COALESCE(SUM(p.amount), 0) as total_spent
FROM 
customers c 
LEFT JOIN orders o 
on 
c.customer_id = o.customer_id 
LEFT JOIN 
payments p 
on 
p.order_id=o.order_id 
GROUP BY c.customer_id,c.name)
SELECT customer_id,
name,
last_order_date,
order_count,
total_spent,
DATEDIFF('2026-09-28',last_order_date) 
AS days_FROM_last_order 
FROM last_order;

-- RFM segmentation

-- recency_segment
-- 0–30 days       → Recent
-- 31–90 days      → At Risk
-- 91+ days        → Inactive

-- frequency_segment
-- 1–2 orders      → Low Frequency
-- 3–5 orders      → Medium Frequency
-- 6+ orders       → High Frequency

-- CUSTOMER_ID, NAME,LasT_ORDER_DATE,ORDER_COUNT,TOTAL_SPENT,DAYS_FROM_LasT_ORDER.

with last_order as 
(SELECT 
c.customer_id,
c.name,
max(o.order_date) as last_order_date,
count(distinct o.order_id) as order_count,
COALESCE(SUM(p.amount), 0) as total_spent
FROM 
customers c LEFT JOIN orders o 
on
c.customer_id=o.customer_id 
LEFT JOIN payments p 
on
p.order_id = o.order_id
GROUP BY c.customer_id,c.name),
recency as (SELECT 
customer_id,
name,
last_order_date,
order_count,
total_spent,
datediff('2026-09-28',last_order_date)as Total_days_FROM_last_order 
FROM last_order)
SELECT customer_id,
name,
last_order_date,
order_count,
total_spent,
Total_days_FROM_last_order,
case
WHEN order_count = 0 THEN 'No Orders'
when Total_days_FROM_last_order <= 30 then 'recent'
when Total_days_FROM_last_order <=90 then 'At Risk'
when Total_days_FROM_last_order >90 then 'Inactive' end as recency_segment,
case
when order_count <=2 then 'low frequency'
 when order_count <=5 then 'medium frequency'
 when order_count >=6 then 'high frequency' end as frequency_segment 
 FROM recency;
 

-- Monetary segments
-- Total Spent	Segment
-- ≤ $500	Low Monetary
-- $500–$1,500	Medium Monetary
-- > $1,500	High Monetary

with last_order as 
(SELECT 
c.customer_id,
c.name,
max(o.order_date) as last_order_date,
count(distinct o.order_id) as order_count,
COALESCE(SUM(p.amount), 0) as total_spent
FROM 
customers c LEFT JOIN orders o 
on
c.customer_id=o.customer_id 
LEFT JOIN payments p 
on
p.order_id = o.order_id
GROUP BY c.customer_id,c.name),
recency as (SELECT 
customer_id,
name,
last_order_date,
order_count,
total_spent,
datediff('2026-09-28',last_order_date)as Total_days_FROM_last_order 
FROM last_order)
SELECT customer_id,
name,
last_order_date,
order_count,
total_spent,
Total_days_FROM_last_order,
case
when Total_days_FROM_last_order <= 30 then 'recent'
when Total_days_FROM_last_order <=90 then 'At Risk'
else 'Inactive' end as recency_segment,
case
WHEN order_count = 0 THEN 'No Orders'
when order_count <=2 then 'low frequency'
 when order_count <=5 then 'medium frequency'
else 'high frequency' end as frequency_segment,
case
when total_spent<=500 then 'low monetary'
when total_spent<=1500 then 'medium monetary'
else 'high monetary' end as monetary_segment 
 FROM recency;


with last_order as 
(SELECT 
c.customer_id,
c.name,
max(o.order_date) as last_order_date,
count(distinct o.order_id) as order_count,
COALESCE(SUM(p.amount), 0) as total_spent
FROM 
customers c LEFT JOIN orders o 
on
c.customer_id=o.customer_id 
LEFT JOIN payments p 
on
p.order_id = o.order_id
GROUP BY c.customer_id,c.name),
recency as (SELECT 
customer_id,
name,
last_order_date,
order_count,
total_spent,
datediff('2026-09-28',last_order_date)as Total_days_FROM_last_order 
FROM last_order),
scores as (SELECT customer_id,
name,
last_order_date,
order_count,
total_spent,
Total_days_FROM_last_order,
case
WHEN last_order_date IS NULL THEN 0
when Total_days_FROM_last_order <= 30 then 5
when Total_days_FROM_last_order <=60 then 4
when Total_days_FROM_last_order <=90 then 3
when Total_days_FROM_last_order <=180 then 2
else 1 end as recency_score,
case
WHEN order_count = 0 THEN 0
when order_count <=2 then 1
when order_count <=4 then 2
when order_count <=6 then 3
when order_count <=8 then 4
else 5 end as frequency_score,
case
WHEN total_spent = 0 THEN 0
when total_spent<=500 then 1
when total_spent<=1000 then 2
when total_spent<=1500 then 3
when total_spent<=2000 then 4
else 5 end as monetary_score 
 FROM recency),
 RFM as (SELECT
 customer_id,
name,
last_order_date,
order_count,
total_spent,
Total_days_FROM_last_order,
recency_score,
frequency_score,
monetary_score,
recency_score +frequency_score+monetary_score as RFM_SCORE
FROM SCORES)
SELECT customer_id,
name,
last_order_date,
order_count,
total_spent,
Total_days_FROM_last_order,
recency_score,
frequency_score,
monetary_score,
RFM_score,
concat
(recency_score,frequency_score,monetary_score) 
as RFM_code FROM 
RFM ORDER BY RFM_score DESC;





	with last_order as 
	(SELECT 
	c.customer_id,
	c.name,
	max(o.order_date) as last_order_date,
	count(distinct o.order_id) as order_count,
	COALESCE(SUM(p.amount), 0) as total_spent
	FROM 
	customers c LEFT JOIN orders o 
	on
	c.customer_id=o.customer_id 
	LEFT JOIN payments p 
	on
	p.order_id = o.order_id
	GROUP BY c.customer_id,c.name),
	recency as (SELECT 
	customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	datediff('2026-09-28',last_order_date)as Total_days_FROM_last_order 
	FROM last_order),
	scores as (SELECT customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	case
    WHEN last_order_date IS NULL THEN 0
	when Total_days_FROM_last_order <= 30 then 5
	when Total_days_FROM_last_order <=60 then 4
	when Total_days_FROM_last_order <=90 then 3
	when Total_days_FROM_last_order <=180 then 2
	else 1 end as recency_score,
	case
    WHEN order_count = 0 THEN 0
	when order_count <=2 then 1
	when order_count <=4 then 2
	when order_count <=6 then 3
	when order_count <=8 then 4
	else 5 end as frequency_score,
	case
    WHEN total_spent = 0 THEN 0
	when total_spent<=500 then 1
	when total_spent<=1000 then 2
	when total_spent<=1500 then 3
	when total_spent<=2000 then 4
	else 5 end as monetary_score 
	 FROM recency),
	 RFM as (SELECT
	 customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	recency_score,
	frequency_score,
	monetary_score,
	recency_score +frequency_score+monetary_score as RFM_SCORE
	FROM SCORES)
	SELECT customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	recency_score,
	frequency_score,
	monetary_score,
	RFM_score,
	concat
	(recency_score,frequency_score,monetary_score) 
	as RFM_code,
	case
    WHEN order_count = 0
        THEN 'Never Purchased'
	when recency_score >=4 and frequency_score>=4 and monetary_score>=4 then "Champions" 
	when recency_score >=4 and frequency_score>=3 then "Loyal Customers"
	when recency_score >=4 and frequency_score<=2 then "New/Promising Customers"
	when recency_score <=2 and frequency_score>=3 then "At Risk"
	when recency_score <=2 and frequency_score <=2 then "Lost Customers"
	else "Potential Loyalist" end as Customer_segment FROM 
	RFM ORDER BY RFM_score DESC;



	with last_order as 
	(SELECT 
	c.customer_id,
	c.name,
	max(o.order_date) as last_order_date,
	count(distinct o.order_id) as order_count,
	COALESCE(SUM(p.amount), 0) as total_spent
	FROM 
	customers c LEFT JOIN orders o 
	on
	c.customer_id=o.customer_id 
	LEFT JOIN payments p 
	on
	p.order_id = o.order_id
	GROUP BY c.customer_id,c.name),
	recency as (SELECT 
	customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	datediff('2026-09-28',last_order_date)as Total_days_FROM_last_order 
	FROM last_order),
	scores as (SELECT customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	case
    WHEN last_order_date IS NULL THEN 0
	when Total_days_FROM_last_order <= 30 then 5
	when Total_days_FROM_last_order <=60 then 4
	when Total_days_FROM_last_order <=90 then 3
	when Total_days_FROM_last_order <=180 then 2
	else 1 end as recency_score,
	case
    WHEN order_count = 0 THEN 0
	when order_count <=2 then 1
	when order_count <=4 then 2
	when order_count <=6 then 3
	when order_count <=8 then 4
	else 5 end as frequency_score,
	case
    WHEN total_spent = 0 THEN 0
	when total_spent<=500 then 1
	when total_spent<=1000 then 2
	when total_spent<=1500 then 3
	when total_spent<=2000 then 4
	else 5 end as monetary_score 
	 FROM recency),
	 RFM as (SELECT
	 customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	recency_score,
	frequency_score,
	monetary_score,
	recency_score +frequency_score+monetary_score as RFM_SCORE
	FROM SCORES),
	customer_segment as (SELECT customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	recency_score,
	frequency_score,
	monetary_score,
	RFM_score,
	concat
	(recency_score,frequency_score,monetary_score) 
	as RFM_code,
	case
    WHEN order_count = 0
        THEN 'Never Purchased'
	when recency_score >=4 and frequency_score>=4 and monetary_score>=4 then "Champions" 
	when recency_score >=4 and frequency_score>=3 then "Loyal Customers"
	when recency_score >=4 and frequency_score<=2 then "New/Promising Customers"
	when recency_score <=2 and frequency_score>=3 then "At Risk"
	when recency_score <=2 and frequency_score <=2 then "Lost Customers"
	else "Potential Loyalist" end as Customer_segment FROM 
	RFM ORDER BY RFM_score DESC)
    SELECT 
    customer_segment,
    count(customer_segment) as customer_count, 
    round(count(customer_segment)/(SELECT count(customer_id) FROM customer_segment)*100,2) as percentage_of_customers
    FROM customer_segment 
    GROUP BY customer_segment;


	with last_order as 
	(SELECT 
	c.customer_id,
	c.name,
	max(o.order_date) as last_order_date,
	count(distinct o.order_id) as order_count,
	COALESCE(SUM(p.amount), 0) as total_spent
	FROM 
	customers c LEFT JOIN orders o 
	on
	c.customer_id=o.customer_id 
	LEFT JOIN payments p 
	on
	p.order_id = o.order_id
	GROUP BY c.customer_id,c.name),
	recency as (SELECT 
	customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	datediff('2026-09-28',last_order_date)as Total_days_FROM_last_order 
	FROM last_order),
	scores as (SELECT customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	case
    WHEN last_order_date IS NULL THEN 0
	when Total_days_FROM_last_order <= 30 then 5
	when Total_days_FROM_last_order <=60 then 4
	when Total_days_FROM_last_order <=90 then 3
	when Total_days_FROM_last_order <=180 then 2
	else 1 end as recency_score,
	case
    WHEN order_count = 0 THEN 0
	when order_count <=2 then 1
	when order_count <=4 then 2
	when order_count <=6 then 3
	when order_count <=8 then 4
	else 5 end as frequency_score,
	case
    WHEN total_spent = 0 THEN 0
	when total_spent<=500 then 1
	when total_spent<=1000 then 2
	when total_spent<=1500 then 3
	when total_spent<=2000 then 4
	else 5 end as monetary_score 
	 FROM recency),
	 RFM as (SELECT
	 customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	recency_score,
	frequency_score,
	monetary_score,
	recency_score +frequency_score+monetary_score as RFM_SCORE
	FROM SCORES),
	customer_segment as (SELECT customer_id,
	name,
	last_order_date,
	order_count,
	total_spent,
	Total_days_FROM_last_order,
	recency_score,
	frequency_score,
	monetary_score,
	RFM_score,
	concat
	(recency_score,frequency_score,monetary_score) 
	as RFM_code,
	case
    WHEN order_count = 0
        THEN 'Never Purchased'
	when recency_score >=4 and frequency_score>=4 and monetary_score>=4 then "Champions" 
	when recency_score >=4 and frequency_score>=3 then "Loyal Customers"
	when recency_score >=4 and frequency_score<=2 then "New/Promising Customers"
	when recency_score <=2 and frequency_score>=3 then "At Risk"
	when recency_score <=2 and frequency_score <=2 then "Lost Customers"
	else "Potential Loyalist" end as Customer_segment FROM 
	RFM ORDER BY RFM_score DESC)
    SELECT 
    customer_segment,
    count(customer_segment) as customer_count, 
    round(count(customer_segment)/(SELECT count(customer_id) FROM customer_segment)*100,2) as percentage_of_customers,
    round(avg(order_count),2) as avg_orders,
    round(avg(total_spent),2) as avg_spent,
    round(avg(Total_days_FROM_last_order),2) as Avg_days_since_last_order
    FROM customer_segment 
    GROUP BY customer_segment;
    
    
   
   
   
   
   
   


-- ***********************************************Important *********************************************************************
-- *********************************************** Data Validation **************************************************************
-- after JOINing customers → orders → payments.
-- If an order has multiple payment records, the JOIN can potentially duplicate order-level information and affect total_spent.
-- Before we build the next major section, I want you to learn how to validate your numbers.
-- Total payments in the payments table = total spending attributed to customers.



SELECT SUM(amount) FROM payments;

SELECT 
	COALESCE(SUM(p.amount), 0) as total_spent
	FROM 
	customers c LEFT JOIN orders o 
	on
	c.customer_id=o.customer_id 
	LEFT JOIN payments p 
	on
	p.order_id = o.order_id
;

-- Validation passed: The customer-level payment total matches
-- the total amount recorded in the payments table.

-- one more professional data-quality check

-- We know:
-- Orders = 5,000
-- Payments = 4,516
-- So some orders don't have payments, which is fine.
-- Now let's check whether any individual order has multiple payment records, because that's the specific situation that could cause duplication when JOINing.

SELECT
    order_id,
    COUNT(*) as payment_count
FROM payments
GROUP BY order_id
HAVING COUNT(*) > 1;

-- -- No order has more than one payment record.
-- Some orders have no recorded payment, as confirmed by the missing-payment check.

-- Data quality finding:
-- Total orders: 5,000
-- Orders with recorded payments: 4,516
-- Orders without recorded payment records: 484
-- Missing payment records do not necessarily indicate unpaid orders.

SELECT count(*) as unpaid_orders
FROM orders o LEFT JOIN 
payments p ON o.order_id = p.order_id
where p.payment_id is null;

-- Validation passed: 484 orders have no recorded payment.

-- =====================================================
-- SECTIon 3: PRODUCT & CATEGORY ANALYSIS
-- =====================================================


-- Category revenue
SELECT c.category_name,
 SUM(oi.quantity) as total_units_sold,
 SUM(oi.quantity*oi.unit_price) as Revenue
FROM categories c LEFT JOIN 
products p
on
c.category_id = p.category_id
LEFT JOIN 
order_items oi 
on
oi.product_id = p.product_id
GROUP BY c.category_name
ORDER BY revenue DESC;


-- What percentage of total company revenue does each category generate?


SELECT SUM(unit_price*quantity) FROM order_items;


with revenue as(SELECT c.category_name,
 SUM(oi.quantity) as total_units_sold,
 SUM(oi.quantity*oi.unit_price) as Category_Revenue
FROM categories c LEFT JOIN 
products p
on
c.category_id = p.category_id
LEFT JOIN 
order_items oi 
on
oi.product_id = p.product_id
GROUP BY c.category_name)
SELECT category_name,
total_units_sold,
category_revenue,
round(category_revenue/(SELECT SUM(unit_price*quantity) FROM order_items)*100,2) as 'Percentage_of_revenue'
FROM revenue
ORDER BY category_revenue DESC;

-- Product-level analysis

-- Which 10 products generate the most revenue?

SELECT 
    c.category_name,
    p.product_name,
    p.product_id,
    SUM(oi.quantity) as units_sold,
    ROUND(SUM(oi.unit_price * oi.quantity), 2) as revenue
FROM
    categories c
        LEFT JOIN
    products p ON c.category_id = p.category_id
        LEFT JOIN
    order_items oi ON oi.product_id = p.product_id
GROUP BY c.category_name , p.product_name,p.product_id
ORDER BY revenue DESC
LIMIT 10;
 
-- High-volume vs high-revenue products


-- Are the products that sell the most units also the products that generate the most revenue?

with revenue as(SELECT 
    c.category_name,
    p.product_name,
    p.product_id,
    SUM(oi.quantity) as units_sold,
    ROUND(SUM(oi.unit_price * oi.quantity), 2) as product_revenue
FROM
    categories c
        LEFT JOIN
    products p ON c.category_id = p.category_id
        LEFT JOIN
    order_items oi ON oi.product_id = p.product_id
GROUP BY c.category_name , p.product_name,p.product_id
ORDER BY product_revenue DESC)
SELECT category_name,
product_name,
product_id,
units_sold,
product_revenue,
round(product_revenue/nullif(units_sold,0),2) as average_selling_price 
FROM revenue;


-- Which products are high-volume but low-revenue, and which are low-volume but high-revenue?\


with PRODUCT_METRICS as(SELECT 
    c.category_name,
    p.product_name,
    p.product_id,
    COALESCE(SUM(oi.quantity), 0) as units_sold,
COALESCE(ROUND(SUM(oi.unit_price * oi.quantity), 2), 0) as product_revenue
FROM
    categories c
        LEFT JOIN
    products p ON c.category_id = p.category_id
        LEFT JOIN
    order_items oi ON oi.product_id = p.product_id
GROUP BY c.category_name , p.product_name,p.product_id
ORDER BY product_revenue DESC),
avgs as(SELECT *,
round(product_revenue/nullif(units_sold,0),2) as average_selling_price 
FROM PRODUCT_METRICS)
SELECT *, ntile(10) over(ORDER BY units_SOLD DESC) as volume_decile,
ntile(10) over(ORDER BY product_revenue DESC) as revenue_decile FROM avgs;


WITH PRODUCT_METRICS as (
    SELECT 
        c.category_name,
        p.product_name,
        p.product_id,
        SUM(oi.quantity) as units_sold,
        ROUND(SUM(oi.unit_price * oi.quantity), 2) as product_revenue
    FROM categories c
    LEFT JOIN products p 
       ON c.category_id = p.category_id
    LEFT JOIN order_items oi 
       ON oi.product_id = p.product_id
    GROUP BY 
        c.category_name,
        p.product_name,
        p.product_id
),

AVGS as (
    SELECT *,
        ROUND(
            product_revenue / NULLIF(units_sold, 0),
            2
        ) as average_selling_price
    FROM PRODUCT_METRICS
),

RANKED_PRODUCTS as (
    SELECT *,
        NTILE(10) OVER (
            ORDER BY units_sold DESC
        ) as volume_decile,
        NTILE(10) OVER (
            ORDER BY product_revenue DESC
        ) as revenue_decile
    FROM AVGS
)

SELECT *,
    CasE
        WHEN revenue_decile <= 5 
             AND volume_decile <= 5
            THEN 'High_Revenue_High_Volume'

        WHEN revenue_decile >= 6 
             AND volume_decile <= 5
            THEN 'Low_Revenue_High_Volume'

        WHEN revenue_decile <= 5 
             AND volume_decile >= 6
            THEN 'High_Revenue_Low_Volume'

        ELSE 'Low_Revenue_Low_Volume'
    END as product_performance

FROM RANKED_PRODUCTS;

-- Product Performance Analysis
-- NTILE(10) ranks products into deciles by units sold and total revenue.
-- Deciles 1–5 are classified as relatively high; deciles 6–10 as relatively low.
-- Products are segmented into four groups basedONrevenue and sales volume.
-- Revenue is not profit; costs and profit margins are not included in this analysis.



-- How many products fall into each performance category, and what percentage of all products does each category represent?

WITH PRODUCT_METRICS as (
    SELECT 
        c.category_name,
        p.product_name,
        p.product_id,
        SUM(oi.quantity) as units_sold,
        ROUND(SUM(oi.unit_price * oi.quantity), 2) as product_revenue
    FROM categories c
    LEFT JOIN products p 
       ON c.category_id = p.category_id
    LEFT JOIN order_items oi 
       ON oi.product_id = p.product_id
    GROUP BY 
        c.category_name,
        p.product_name,
        p.product_id
),

AVGS as (
    SELECT *,
        ROUND(
            product_revenue / NULLIF(units_sold, 0),
            2
        ) as average_selling_price
    FROM PRODUCT_METRICS
),

RANKED_PRODUCTS as (
    SELECT *,
        NTILE(10) OVER (
            ORDER BY units_sold DESC
        ) as volume_decile,
        NTILE(10) OVER (
            ORDER BY product_revenue DESC
        ) as revenue_decile
    FROM AVGS
),

Performance_category as (SELECT *,
    CasE
        WHEN revenue_decile <= 5 
             AND volume_decile <= 5
            THEN 'High_Revenue_High_Volume'

        WHEN revenue_decile >= 6 
             AND volume_decile <= 5
            THEN 'Low_Revenue_High_Volume'

        WHEN revenue_decile <= 5 
             AND volume_decile >= 6
            THEN 'High_Revenue_Low_Volume'

        ELSE 'Low_Revenue_Low_Volume'
    END as product_performance

FROM RANKED_PRODUCTS)
SELECT product_performance,
count(*) as product_count, 
round(count(*)/(SELECT count(product_performance) FROM performance_category)*100,2) 
as percentage
FROM performance_category 
GROUP BY product_performance;



-- Which product categories generate the most revenue, and how does their sales volume compare?

WITH PRODUCT_METRICS as (
    SELECT 
        c.category_name,
        p.product_name,
        p.product_id,
        SUM(oi.quantity) as units_sold,
        ROUND(SUM(oi.unit_price * oi.quantity), 2) as product_revenue
    FROM categories c
    LEFT JOIN products p 
       ON c.category_id = p.category_id
    LEFT JOIN order_items oi 
       ON oi.product_id = p.product_id
    GROUP BY 
        c.category_name,
        p.product_name,
        p.product_id
),
total as (SELECT category_name, SUM(units_sold) as total_units_sold,
SUM(product_revenue) as total_revenue,
round(avg(product_revenue),2) as average_revenue_per_product
FROM product_metrics
GROUP BY category_name)
SELECT *,
round(total_revenue/(SELECT SUM(product_revenue) FROM product_metrics)*100,2) as percentage_of_total_revenue
FROM
total
ORDER BY percentage_of_total_revenue DESC;


-- Finding cumulative percentage:


WITH PRODUCT_METRICS as (
    SELECT 
        c.category_name,
        p.product_name,
        p.product_id,
        SUM(oi.quantity) as units_sold,
        ROUND(SUM(oi.unit_price * oi.quantity), 2) as product_revenue
    FROM categories c
    LEFT JOIN products p 
       ON c.category_id = p.category_id
    LEFT JOIN order_items oi 
       ON oi.product_id = p.product_id
    GROUP BY 
        c.category_name,
        p.product_name,
        p.product_id
),
 total as (SELECT category_name, SUM(units_sold) as total_units_sold,
SUM(product_revenue) as total_revenue,
round(avg(product_revenue),2) as average_revenue_per_product
FROM product_metrics
GROUP BY category_name),
pct_of_total as (SELECT *,
round(total_revenue/(SELECT SUM(product_revenue) FROM product_metrics)*100,2) as percentage_of_total_revenue
FROM
total
)
SELECT *,
SUM(percentage_of_total_revenue) over (ORDER BY total_revenue DESC) as cumulative_percentage
FROM 
pct_of_total
ORDER BY percentage_of_total_revenue DESC;

-- Which customers generate the most revenue, and how many different products/categories have they purchased?

-- *********************************************************For each customer, calculate:****************************************************************************
-- *****************customer_id,name,total_spent,number_of_orders,number_of_unique_products_purchased,number_of_unique_categories_purchased**************************
SELECT SUM(AMOUNT) FROM PAYMENTS;



WITH customer_spending as (
    SELECT
        o.customer_id,
        COALESCE(SUM(p.amount), 0) as total_spent
    FROM orders o
    LEFT JOIN payments p
       ON p.order_id = o.order_id
    GROUP BY o.customer_id
),
customer_variety as (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) as number_of_orders,
        COUNT(DISTINCT pr.product_id)
            as number_of_unique_products_purchased,
        COUNT(DISTINCT ct.category_id)
            as number_of_unique_categories_purchased
    FROM orders o
    LEFT JOIN order_items oi
       ON oi.order_id = o.order_id
    LEFT JOIN products pr
       ON pr.product_id = oi.product_id
    LEFT JOIN categories ct
       ON ct.category_id = pr.category_id
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.name,
    COALESCE(cs.total_spent, 0) as total_spent,
    COALESCE(cv.number_of_orders, 0) as number_of_orders,
    COALESCE(cv.number_of_unique_products_purchased, 0)
        as number_of_unique_products_purchased,
    COALESCE(cv.number_of_unique_categories_purchased, 0)
        as number_of_unique_categories_purchased
FROM customers c
LEFT JOIN customer_spending cs
   ON cs.customer_id = c.customer_id
LEFT JOIN customer_variety cv
   ON cv.customer_id = c.customer_id
ORDER BY total_spent DESC;








WITH customer_spending as (
    SELECT
        o.customer_id,
        COALESCE(SUM(p.amount), 0) as total_spent
    FROM orders o
    LEFT JOIN payments p
       ON p.order_id = o.order_id
    GROUP BY o.customer_id
),
customer_variety as (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) as number_of_orders,
        COUNT(DISTINCT pr.product_id)
            as number_of_unique_products_purchased,
        COUNT(DISTINCT ct.category_id)
            as number_of_unique_categories_purchased
    FROM orders o
    LEFT JOIN order_items oi
       ON oi.order_id = o.order_id
    LEFT JOIN products pr
       ON pr.product_id = oi.product_id
    LEFT JOIN categories ct
       ON ct.category_id = pr.category_id
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.name,
    COALESCE(cs.total_spent, 0) as total_spent,
    ROUND(
        cs.total_spent / NULLIF(cv.number_of_orders, 0),
        2
    ) as average_order_value,
    COALESCE(cv.number_of_orders, 0) as number_of_orders,
    COALESCE(cv.number_of_unique_products_purchased, 0)
        as number_of_unique_products_purchased,
    COALESCE(cv.number_of_unique_categories_purchased, 0)
        as number_of_unique_categories_purchased
FROM customers c
LEFT JOIN customer_spending cs
   ON cs.customer_id = c.customer_id
LEFT JOIN customer_variety cv
   ON cv.customer_id = c.customer_id
ORDER BY number_of_unique_products_purchased DESC;


-- let's create customer groups based on the number of unique products purchased.
-- 1–5 products → Low variety
-- 6–10 → Moderate variety
-- 11–20 → High variety
-- 21+ → Very high variety


WITH customer_metrics as (
    SELECT
        c.customer_id,
        c.name,
        COUNT(DISTINCT pr.product_id) as unique_products
    FROM customers c
    LEFT JOIN orders o
       ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
       ON oi.order_id = o.order_id
    LEFT JOIN products pr
       ON pr.product_id = oi.product_id
    GROUP BY
        c.customer_id,
        c.name
)
SELECT
    customer_id,
    name,
    unique_products,
    CasE
        WHEN unique_products <= 5 THEN 'Low Variety'
        WHEN unique_products <= 10 THEN 'Moderate Variety'
        WHEN unique_products <= 20 THEN 'High Variety'
        ELSE 'Very High Variety'
    END as product_variety
FROM customer_metrics
ORDER BY unique_products DESC;


-- Do customers who purchase a wider variety of products spend more money?

WITH customer_spending as (
    SELECT
    
        o.customer_id,
        COALESCE(SUM(p.amount), 0) as total_spent
    FROM orders o
    LEFT JOIN payments p
       ON p.order_id = o.order_id
    GROUP BY o.customer_id
),
customer_metrics as (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) as number_of_orders,
        COUNT(DISTINCT pr.product_id) as unique_products,
        COUNT(DISTINCT ct.category_id)
            as number_of_unique_categories_purchased
    FROM customers c
    LEFT JOIN orders o
       ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
       ON oi.order_id = o.order_id
    LEFT JOIN products pr
       ON pr.product_id = oi.product_id
    LEFT JOIN categories ct
       ON ct.category_id = pr.category_id
    GROUP BY c.customer_id
),
product_variety as (
    SELECT
        cm.customer_id,
        COALESCE(cs.total_spent, 0) as total_spent,
        cm.number_of_orders,
        cm.unique_products,
        cm.number_of_unique_categories_purchased,
        CasE
            WHEN cm.unique_products <= 5 THEN 'Low Variety'
            WHEN cm.unique_products <= 10 THEN 'Moderate Variety'
            WHEN cm.unique_products <= 20 THEN 'High Variety'
            ELSE 'Very High Variety'
        END as product_variety
    FROM customer_metrics cm
    LEFT JOIN customer_spending cs
       ON cs.customer_id = cm.customer_id
)
SELECT
    product_variety,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_total_spent,
    ROUND(AVG(number_of_orders), 2) as avg_number_of_orders,
    ROUND(AVG(number_of_unique_categories_purchased), 2)
        as avg_unique_categories
FROM product_variety
GROUP BY product_variety
ORDER BY customer_count DESC;

-- Customer segmentation by product variety shows a positive association between product breadth and customer spending.
-- Customer Product Variety: Key Findings
-- Analysis based on 1,000 customers and 10,331 order-item records.
--
-- Low Variety customers:
-- 187 customers, average spending $1,141.20,
-- average 2.42 orders.
--
-- Moderate Variety customers:
-- 447 customers, average spending $2,581.11,
-- average 4.55 orders.
--
-- High Variety customers:
-- 361 customers, average spending $4,602.47,
-- average 6.82 orders.
--
-- Very High Variety customers:
-- 5 customers, average spending $8,745.26,
-- average 10.80 orders.
--
-- High Variety customers spend approximately 4.03 times
-- as much as Low Variety customers on average.
--
-- The results show a positive association between product
-- variety and recorded spending, not a causal relationship.
-- Differences in order frequency may partly explain the
-- spending gap.
--
-- The Very High Variety group contains only five customers,
-- so its average should be interpreted cautiously.



WITH customer_spending as (
    SELECT
        o.customer_id,
        COALESCE(SUM(p.amount), 0) as total_spent
    FROM orders o
    LEFT JOIN payments p
       ON p.order_id = o.order_id
    GROUP BY o.customer_id
),
customer_metrics as (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) as number_of_orders,
        COUNT(DISTINCT pr.product_id) as unique_products,
        COUNT(DISTINCT ct.category_id)
            as number_of_unique_categories_purchased
    FROM customers c
    LEFT JOIN orders o
       ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
       ON oi.order_id = o.order_id
    LEFT JOIN products pr
       ON pr.product_id = oi.product_id
    LEFT JOIN categories ct
       ON ct.category_id = pr.category_id
    GROUP BY c.customer_id
),
product_variety as (
    SELECT
        cm.customer_id,
        COALESCE(cs.total_spent, 0) as total_spent,
        cm.number_of_orders,
        cm.unique_products,
        cm.number_of_unique_categories_purchased,
        CasE
            WHEN cm.unique_products <= 5 THEN 'Low Variety'
            WHEN cm.unique_products <= 10 THEN 'Moderate Variety'
            WHEN cm.unique_products <= 20 THEN 'High Variety'
            ELSE 'Very High Variety'
        END as product_variety
    FROM customer_metrics cm
    LEFT JOIN customer_spending cs
       ON cs.customer_id = cm.customer_id
)
SELECT
    product_variety,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_total_spent,
    ROUND(AVG(number_of_orders), 2) as avg_number_of_orders,
    ROUND(AVG(number_of_unique_categories_purchased), 2)
        as avg_unique_categories,
    ROUND(
        AVG(total_spent / NULLIF(number_of_orders, 0)), 2
    ) as avg_customer_spend_per_order,
    ROUND(AVG(unique_products), 2) as avg_unique_products
FROM product_variety
GROUP BY product_variety
ORDER BY customer_count DESC;



SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_order_items,
    (SELECT COUNT(*) FROM payments) AS total_payment_records,
    (SELECT ROUND(SUM(amount), 2) FROM payments) AS total_recorded_payments,
    (SELECT ROUND(SUM(quantity * unit_price), 2) FROM order_items) AS total_product_sales_value;
    
    
SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT order_id) AS orders_with_items,
    COUNT(DISTINCT product_id) AS unique_products,
    MIN(order_item_id) AS minimum_item_id,
    MAX(order_item_id) AS maximum_item_id
FROM order_items;

SELECT
    oi.product_id,
    COUNT(*) AS order_item_count
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY oi.product_id
ORDER BY order_item_count DESC;


SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    MIN(product_id) AS minimum_product_id,
    MAX(product_id) AS maximum_product_id
FROM products;

SELECT
    FLOOR((order_item_id - 1) / 1000) + 1 AS id_group,
    MIN(order_item_id) AS first_id,
    MAX(order_item_id) AS last_id,
    COUNT(*) AS actual_records
FROM order_items
GROUP BY FLOOR((order_item_id - 1) / 1000) + 1
ORDER BY id_group;


SELECT
    COUNT(*) AS records_in_suspected_range
FROM order_items
WHERE order_item_id BETWEEN 9001 AND 9500;

USE ecommerce_analytics;

SELECT
    COUNT(*) AS total_order_items,
    COUNT(CASE
        WHEN order_item_id BETWEEN 9001 AND 9500
        THEN 1
    END) AS restored_records
FROM order_items;