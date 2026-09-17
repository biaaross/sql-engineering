-- ============================================================
-- Exercise 9
-- Find customers who have at least 2 completed orders.
-- ============================================================

SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    COUNT(o.id) AS completed_orders
FROM customers AS c
INNER JOIN orders AS o
    ON c.id = o.customer_id
WHERE
    o.status = 'completed'
GROUP BY
    c.id,
    c.name
HAVING
    COUNT(o.id) >= 2
ORDER BY
    completed_orders DESC;