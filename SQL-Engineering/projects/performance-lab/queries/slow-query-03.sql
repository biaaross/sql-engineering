-- Performance Lab - Case 03
-- Scenario:
-- Retrieve a page of completed orders
-- sorted by order date.
-- The application requests a deep page.

SELECT
id,
customer_id,
status,
order_date
FROM orders
WHERE status = 'completed'
ORDER BY order_date DESC
LIMIT 50 OFFSET 500000;
