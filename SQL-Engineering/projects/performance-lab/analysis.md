# SQL Performance Lab — Analysis

## Overview

This document analyzes three SQL performance cases focused on common query optimization problems:

1. Non-SARGable date filtering
2. JOIN performance and composite indexing
3. Deep OFFSET pagination and keyset pagination

The goal of this lab is to understand how query structure and index design affect database performance.

> **Note:** The current execution-plan analysis is based on expected optimizer behavior. Actual execution-plan metrics such as logical reads, CPU time, elapsed time, estimated rows, and actual rows should be collected from SQL Server and added to the `before/` and `after/` files once the database environment is available.

---

# Case 01 — SARGability and Date Filtering

## Problem

The original query filters orders by applying the `YEAR()` function directly to the `order_date` column.

```sql
WHERE customer_id = 125000
  AND YEAR(order_date) = 2025;
```

The main issue is the use of a function on the indexed column.

Applying `YEAR()` to `order_date` makes the predicate non-SARGable and can prevent efficient index-based range searching on the date column.

## Before

The original query:

```sql
SELECT
    id,
    customer_id,
    status,
    order_date
FROM orders
WHERE customer_id = 125000
  AND YEAR(order_date) = 2025;
```

Expected behavior:

* The database may scan a large portion of the table or index.
* `YEAR(order_date)` must be evaluated for candidate rows.
* A normal index on `order_date` cannot be used as efficiently for direct range seeking.
* The number of rows examined can be significantly larger than the number of rows returned.

## Optimization

The date condition was rewritten as a range predicate:

```sql
WHERE customer_id = 125000
  AND order_date >= '2025-01-01'
  AND order_date < '2026-01-01';
```

A composite index can then be designed around the query:

```sql
CREATE INDEX IX_orders_customer_date
ON orders(customer_id, order_date);
```

## Why This Index?

The query uses:

* `customer_id` as an equality predicate
* `order_date` as a range predicate

Therefore:

```text
(customer_id, order_date)
```

provides an appropriate index structure for the query.

## Expected Result

The optimized query can potentially use an Index Seek instead of scanning a large portion of the data.

Expected improvements:

* Fewer rows examined
* Lower logical reads
* Lower CPU usage
* More efficient date filtering
* Better scalability as the orders table grows

---

# Case 02 — JOIN Performance and Composite Indexing

## Problem

The second case joins customers and orders and filters the orders by status and date.

Original query:

```sql
SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    o.id AS order_id,
    o.order_date,
    o.status
FROM customers AS c
INNER JOIN orders AS o
    ON c.id = o.customer_id
WHERE o.status = 'completed'
  AND YEAR(o.order_date) = 2025;
```

There are three important columns involved in the `orders` table:

```text
customer_id → JOIN
status      → equality filter
order_date  → date filter
```

The date predicate is also non-SARGable because
