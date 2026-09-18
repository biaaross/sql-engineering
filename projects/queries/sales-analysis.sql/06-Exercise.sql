SELECT
    o.status,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.id = oi.order_id
GROUP BY
    o.status
ORDER BY
    total_revenue DESC;
