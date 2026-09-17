-- ============================================================
-- Exercise 5
-- Find customers who have never placed an order.
-- ============================================================

WITH customers_without_orders AS (
    SELECT
        c.id,
        c.name
    FROM customers AS c
    LEFT JOIN orders AS o
        ON c.id = o.customer_id
    WHERE
        o.id IS NULL
)

SELECT
    *
FROM customers_without_orders;