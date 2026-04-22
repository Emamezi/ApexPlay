--Stakeholder specific Questions
-- 1.What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years?
-- 2.For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver?
-- 3.What was the refund rate and refund count for each product overall? 
-- 4.Within each region, what is the most popular product?
-- 5.How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 

-- Query Solution
-- 1.What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 
-- output that shows count grouped by quarter, join the orders, customers and geo_lookup tables togetgher and would sort by descending 

SELECT DATE_TRUNC(orders.purchase_ts, quarter)AS quarter,
 COUNT(DISTINCT orders.id) as order_count,
 ROUND(SUM(orders.usd_price),2) as total_sales,
 ROUND(AVG(orders.usd_price),2) AS AOV
FROM core.orders
LEFT JOIN core.customers 
  ON customers.id=orders.customer_id
LEFT JOIN core.geo_lookup 
  ON customers.country_code=geo_lookup.country_code
WHERE lower(product_name) LIKE "%macbook%"
 AND geo_lookup.region="NA"
 GROUP BY   1
 ORDER BY 1 DESC;

-- What is the average quarterly order count and total sales for Macbooks sold in North America?
--> In North America, an averag eof 123 untis were sold per quarter generating about $196k in revenue per quarter

WITH quarterly_metrics AS  ( 
  SELECT DATE_TRUNC(orders.purchase_ts, quarter) as quarter,
  COUNT(DISTINCT orders.id) AS order_count,
  ROUND(sum(orders.usd_price),2) AS total_sales
  FROM core.orders
  LEFT JOIN core.customers 
    ON customers.id=orders.customer_id
  LEFT JOIN   core.geo_lookup 
    ON customers.country_code=geo_lookup.country_code
  WHERE LOWER(product_name) LIKE "%macbook%" 
  AND geo_lookup.region="NA"
  GROUP BY  1
  ORDER BY  1 DESC
)

SELECT AVG(order_count) AS average_order_count,
AVG(total_sales) AS average_total_sales
FROM quarterly_metrics;

--2. For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 
-- calculate differnce between purchase_ts and ship_ts, filter to product purchased in 2022 on platform website or mobile in any year and group by region

SELECT geo_lookup.region,
 AVG(DATE_DIFF(order_status.delivery_ts, 
 order_status.purchase_ts, day)) AS delivery_time
FROM core.order_status
LEFT JOIN  core.orders
  ON orders.id=order_status.order_id
 LEFT JOIN core.customers
  ON customers.id=orders.customer_id
 LEFT JOIN core.geo_lookup
  ON geo_lookup.country_code=customers.country_code
  WHERE( EXTRACT(year FROM orders.purchase_ts)=2022 AND orders.purchase_platform="website") 
  OR purchase_platform ="mobile app"
GROUP BY 1
ORDER BY 2 DESC;

-- Bonus: Rewrite this query for website purchases made in 2022 or Samsung purchases made in 2021, expressing time to deliver in weeks instead of days.
-- select distinct product name form orders table
SELECT DISTINCT product_name
FROM core.orders;

SELECT geo_lookup.region,
 AVG(DATE_DIFF(order_status.delivery_ts,order_status.purchase_ts, week)) AS delivery_time_weeks
FROM core.order_status
LEFT JOIN  core.orders
  ON orders.id=order_status.order_id
LEFT JOIN core.customers
 ON customers.id=orders.customer_id
LEFT JOIN core.geo_lookup 
  ON geo_lookup.country_code=customers.country_code
WHERE (EXTRACT(year FROM order_status.purchase_ts)=2022 AND orders.purchase_platform="website")
 OR (LOWER(orders.product_name) LIKE "samsunng%" AND EXTRACT(year FROM order_status.purchase_ts)=2021)
GROUP BY 1
ORDER BY  2 DESC;

-- 3. What was the refund rate and refund count for each product overall? 
-- case when refun_ts is null then 0 else 1, count is refund column and avg same column 
--> Top refunded product-Thinkpad laptop  (11.7% refund rate). Macbook air laptop and Apple iphone also have high refund rates(11.4% and 7.6% respectively). AppleAirpods Headphones have the highest number of refunds (2.6K)
SELECT 
  CASE WHEN  orders.product_name='27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE orders.product_name END AS product_clean,
  SUM(CASE WHEN  refund_ts IS NULL THEN 0 ELSE 1 END) AS refund_count,
  AVG(CASE WHEN refund_ts IS NULL  THEN 0 ELSE 1 END)*100 AS refund_rate
FROM core.order_status
LEFT JOIN  core.orders
  ON orders.id=order_status.order_id
GROUP BY  1
ORDER BY 3 DESC;

-- 4. Within each region, what is the most popular product? 
-- > Apple Airpods Headphones were the most popular product across all regions by order volume, highest in NA (18K)
WITH product_order_count_cte AS (
  SELECT geo_lookup.region AS region,
  CASE WHEN orders.product_name='27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE orders.product_name END AS product_clean,
  COUNT(DISTINCT orders.id) AS order_count
  FROM core.orders
  LEFT JOIN  core.customers
    ON orders.customer_id=customers.id
  LEFT JOIN core.geo_lookup
    ON geo_lookup.country_code=customers.country_code
  GROUP BY 1,2
)

SELECT * ,
 ROW_NUMBER() OVER(PARTITION BY  region ORDER BY order_count DESC  ) AS product_rank
FROM product_order_count_cte 
QUALIFY ROW_NUMBER() OVER(PARTITION BY region ORDER BY order_count DESC)=1;


-- 5. How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 
--> Loyalty and non-loyalty customers take about the same time to make their first purchase after sign-up,~3.4 months for loyalty vs ~3.5 months for non-loyalty customers
SELECT 
 customers.loyalty_program,
 ROUND(AVG(DATE_DIFF(orders.purchase_ts,customers.created_on,day)),1) AS days_to_order,
 ROUND(AVG(DATE_DIFF(orders.purchase_ts,customers.created_on,month)),1) AS month_to_order,
FROM core.customers
LEFT JOIN core.orders 
  ON customers.id=orders.customer_id
GROUP BY 1;

-- Bonus: Update this query to split the time to purchase per loyalty program, per purchase platform. Return the number of records to benchmark the severity of nulls.
-->Loyalyt customers who sign-up from mobile place their first order faster than non-loyalty members~91 days vs 100 days. Likely due to frequent app user engagements such as push notifications and cart reminders
SELECT loyalty_program,
 orders.purchase_platform AS platform,
 ROUND(AVG(DATE_DIFF(purchase_ts,created_on,day)),2) AS days_to_order,
 ROUND(AVG(DATE_DIFF(purchase_ts,created_on,month)),2) AS month_to_order,
COUNT(*) AS row_count
FROM core.customers
LEFT JOIN  core.orders 
  ON customers.id=orders.customer_id
GROUP BY 1,2
