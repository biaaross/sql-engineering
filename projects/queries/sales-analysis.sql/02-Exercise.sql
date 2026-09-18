SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    COUNT(o.id) AS completed_orders
FROM orders AS o
WHERE
    o.status = 'completed'
GROUP BY
    DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY
    order_month;
