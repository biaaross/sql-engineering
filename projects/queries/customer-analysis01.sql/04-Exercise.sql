-- ============================================================
-- Exercise 4
-- Count the completed orders for each customer.
-- ============================================================

SELECT
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
ORDER BY
    completed_orders DESC;

