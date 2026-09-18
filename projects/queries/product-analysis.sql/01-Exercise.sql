WITH product_sales AS (
    SELECT
        p.category,
        p.id AS product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_quantity_sold
    FROM products AS p
    INNER JOIN order_items AS oi
        ON p.id = oi.product_id
    INNER JOIN orders AS o
        ON oi.order_id = o.id
    WHERE
        o.status = 'completed'
    GROUP BY
        p.category,
        p.id,
        p.name
),

category_top_sales AS (
    SELECT
        category,
        MAX(total_quantity_sold) AS max_quantity_sold
    FROM product_sales
    GROUP BY
        category
)

SELECT
    ps.category,
    ps.product_name,
    ps.total_quantity_sold
FROM product_sales AS ps
INNER JOIN category_top_sales AS cts
    ON ps.category = cts.category
    AND ps.total_quantity_sold = cts.max_quantity_sold
ORDER BY
    ps.category;
