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
    AVG(order_total) AS average_order_value
FROM order_totals;
