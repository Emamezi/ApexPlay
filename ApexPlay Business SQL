-- What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 
-- output that shows count grouped by quarter, join the orders, cutomers and geo_lookup tables togetgher would sort by descending 

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

select avg(order_count) as average_order_count,
avg(total_sales) as average_total_sales
from quarterly_metrics;
