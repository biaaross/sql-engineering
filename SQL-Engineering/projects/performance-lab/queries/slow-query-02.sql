-- Performance Lab - Case 02
-- Scenario:
-- Find the completed orders and customer information
-- for customers whose orders were placed in 2025.

SELECT
c.id AS customer_id,
c.name AS customer_name,
o.id AS order_id,
o.order_date,
o.status
FROM customers AS c
INNER JOIN orders AS o
ON c.id = o.customer_id
WHERE o.status = 'completed'
AND YEAR(o.order_date) = 2025;
