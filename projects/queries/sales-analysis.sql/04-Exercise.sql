WITH order_totals AS (
    SELECT
        o.id AS order_id,
        SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.id = oi.order_id
    WHERE
        o.status = 'completed'
    GROUP BY
        o.id
)

SELECT
    order_id,
    order_total
FROM order_totals
WHERE order_total = (
    SELECT MAX(order_total)
    FROM order_totals
);