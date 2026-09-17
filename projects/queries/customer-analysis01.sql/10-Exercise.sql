-- ============================================================
-- Exercise 10
-- Rank customers by their total spending on completed orders.
-- ============================================================

WITH customer_spending AS (
    SELECT
        c.id AS customer_id,
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
)

SELECT
    customer_id,
    customer_name,
    total_spent,
    RANK() OVER (
        ORDER BY total_spent DESC
    ) AS spending_rank
FROM customer_spending
ORDER BY
    spending_rank;