SELECT
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.id = oi.order_id
WHERE
    o.status = 'completed';
