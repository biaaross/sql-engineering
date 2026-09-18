-- ============================================================
-- Exercise 8
-- Find customers whose average completed order value
-- is greater than 10,000 TL.
-- ============================================================

WITH order_totals AS (
    SELECT
        o.id AS order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.id = oi.order_id
    WHERE
        o.status = 'completed'
    GROUP BY
        o.id,
        o.customer_id
)

SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    AVG(ot.order_total) AS average_order_value
FROM customers AS c
INNER JOIN order_totals AS ot
    ON c.id = ot.customer_id
GROUP BY
    c.id,
    c.name
HAVING
    AVG(ot.order_total) > 10000
ORDER BY
    average_order_value DESC;
