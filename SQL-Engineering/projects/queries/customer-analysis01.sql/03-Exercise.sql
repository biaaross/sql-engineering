-- ============================================================
-- Exercise 3
-- Calculate the average order value of each customer
-- based only on completed orders.
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
