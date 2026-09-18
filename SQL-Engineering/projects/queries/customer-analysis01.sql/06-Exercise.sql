-- ============================================================
-- Exercise 6
-- Show each customer's total spending and number of
-- completed orders.
-- ============================================================

SELECT
    c.name AS customer_name,
    COUNT(o.id) AS completed_orders,
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