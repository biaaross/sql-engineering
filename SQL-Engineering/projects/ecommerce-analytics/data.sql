-- =========================================================
-- E-Commerce Analytics
-- Sample Dataset
-- =========================================================

USE ecommerce_analytics;


-- =========================================================
-- Customers
-- =========================================================

INSERT INTO customers (name, email, country, created_at) VALUES
('Arda Yilmaz', 'arda@example.com', 'Turkey', '2025-01-15 10:20:00'),
('Ahmet Demir', 'ahmet@example.com', 'Turkey', '2025-02-10 14:30:00'),
('Elif Kaya', 'elif@example.com', 'Turkey', '2025-03-05 09:15:00'),
('Zeynep Aydin', 'zeynep@example.com', 'Germany', '2025-03-18 16:45:00'),
('Mehmet Can', 'mehmet@example.com', 'Turkey', '2025-04-01 11:10:00'),
('John Smith', 'john@example.com', 'United Kingdom', '2025-04-20 13:25:00'),
('Emma Wilson', 'emma@example.com', 'United Kingdom', '2025-05-12 15:40:00'),
('Sophie Brown', 'sophie@example.com', 'Germany', '2025-06-01 10:05:00'),
('Daniel Miller', 'daniel@example.com', 'United States', '2025-06-15 17:20:00'),
('Michael Johnson', 'michael@example.com', 'United States', '2025-07-03 12:30:00');


-- =========================================================
-- Products
-- =========================================================

INSERT INTO products (name, category, price, created_at) VALUES
('Laptop Pro 15', 'Electronics', 45000.00, '2025-01-05 09:00:00'),
('Wireless Mouse', 'Electronics', 850.00, '2025-01-08 10:00:00'),
('Mechanical Keyboard', 'Electronics', 2500.00, '2025-01-10 11:00:00'),
('USB-C Hub', 'Electronics', 1200.00, '2025-01-12 12:00:00'),
('Office Chair', 'Furniture', 7500.00, '2025-02-01 09:30:00'),
('Standing Desk', 'Furniture', 12000.00, '2025-02-05 14:00:00'),
('Notebook', 'Stationery', 120.00, '2025-02-10 10:30:00'),
('Pen Set', 'Stationery', 180.00, '2025-02-12 13:00:00'),
('Backpack', 'Accessories', 1500.00, '2025-03-01 15:00:00'),
('Monitor 27', 'Electronics', 9500.00, '2025-03-10 09:45:00');


-- =========================================================
-- Orders
-- =========================================================

INSERT INTO orders (customer_id, status, order_date) VALUES
(1, 'completed', '2025-01-20 10:00:00'),
(1, 'completed', '2025-02-15 11:30:00'),
(2, 'completed', '2025-02-20 14:00:00'),
(2, 'cancelled', '2025-03-01 16:20:00'),
(3, 'completed', '2025-03-15 09:10:00'),
(3, 'completed', '2025-04-10 13:40:00'),
(4, 'completed', '2025-04-18 15:00:00'),
(5, 'pending', '2025-05-02 10:15:00'),
(5, 'completed', '2025-05-15 12:00:00'),
(6, 'completed', '2025-06-01 14:30:00'),
(7, 'completed', '2025-06-12 11:20:00'),
(8, 'cancelled', '2025-06-20 17:00:00'),
(9, 'completed', '2025-07-05 09:45:00'),
(10, 'completed', '2025-07-10 16:30:00'),
(1, 'completed', '2025-08-01 10:00:00');


-- =========================================================
-- Order Items
-- =========================================================

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 45000.00),
(1, 2, 2, 850.00),

(2, 3, 1, 2500.00),
(2, 4, 1, 1200.00),

(3, 5, 1, 7500.00),
(3, 7, 3, 120.00),

(4, 6, 1, 12000.00),

(5, 9, 1, 1500.00),
(5, 8, 2, 180.00),

(6, 10, 2, 9500.00),

(7, 2, 1, 850.00),
(7, 3, 1, 2500.00),

(8, 1, 1, 45000.00),

(9, 6, 1, 12000.00),
(9, 5, 1, 7500.00),

(10, 4, 2, 1200.00),

(11, 9, 2, 1500.00),

(12, 7, 5, 120.00),

(13, 1, 1, 45000.00),

(14, 10, 1, 9500.00),
(14, 2, 1, 850.00),

(15, 3, 2, 2500.00);