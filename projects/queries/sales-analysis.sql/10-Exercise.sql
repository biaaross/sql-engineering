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
),

monthly_comparison AS (
    SELECT
        order_month,
        total_revenue,
        LAG(total_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    order_month,
    total_revenue,
    previous_month_revenue,
    ROUND(
        (
            (total_revenue - previous_month_revenue)
            / previous_month_revenue
        ) * 100,
        2
    ) AS revenue_change_percentage
FROM monthly_comparison
ORDER BY
    order_month;
