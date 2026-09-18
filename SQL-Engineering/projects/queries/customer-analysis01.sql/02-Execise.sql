
-- ============================================================
-- Exercise 2
-- Calculate the total spending of each customer
-- based only on completed orders.
-- ============================================================

SELECT
    c.name AS customer_name,
    SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers AS c
INNER JOIN orders AS o
    ON c.id = o.customer_id
INNER JOIN order_items AS oi
    ON o.id = oi.order_id
WHERE
    o.status = 'completed'
GROUP BY
    c.id,
    c.name
ORDER BY
    total_spent DESC;