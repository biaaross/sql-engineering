-- ============================================================
-- Exercise 1
-- List each customer's name and total number of orders.
-- ============================================================

SELECT
    c.name AS customer_name,
    COUNT(o.id) AS total_orders
FROM customers AS c
INNER JOIN orders AS o
    ON c.id = o.customer_id
GROUP BY
    c.id,
    c.name
ORDER BY
    total_orders DESC;