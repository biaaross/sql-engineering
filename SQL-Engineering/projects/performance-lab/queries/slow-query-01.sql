-- Performance Lab - Case 01
-- Scenario:
-- Find the completed orders of a specific customer
-- for the year 2025.

SELECT
id,
customer_id,
status,
order_date
FROM orders
WHERE customer_id = 125000
AND YEAR(order_date) = 2025;
