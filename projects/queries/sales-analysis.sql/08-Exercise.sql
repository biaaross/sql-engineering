WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.id = oi.order_id
    WHERE
        o.status = 'completed'
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m')
)

SELECT
    order_month,
    total_revenue
FROM monthly_sales
ORDER BY
    order_month;