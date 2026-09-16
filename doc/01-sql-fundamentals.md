# SQL Query Optimization — Day 1

## Overview

This section covers the fundamental concepts required to understand SQL query performance and index design.

The main goal is not simply to learn how to create indexes, but to understand:

* Why indexes improve query performance
* When an index is useful
* How MySQL chooses an access path
* How to read an `EXPLAIN` plan
* How cardinality and selectivity affect index usage
* How composite indexes work
* Why column order matters
* How to design indexes based on real application workload
* Why indexes also introduce maintenance costs

> **Professional mindset:**
> An index should not be created simply because a column is frequently used. It should be designed according to query patterns, data distribution, workload, and maintenance cost.

---

# 1. What Is an Index?

An index is an additional data structure that provides the database with an alternative way to access data efficiently.

Without a suitable index, the database may need to inspect a large number of rows to find matching records.

Example:

```sql
CREATE INDEX idx_orders_customer
ON orders(customer_id);
```

This creates an index on `customer_id`.

A query such as:

```sql
SELECT *
FROM orders
WHERE customer_id = 1250;
```

can potentially use this index to find matching rows more efficiently.

### Important

An index does **not** guarantee that the database will use it.

The optimizer evaluates the available access paths and chooses what it considers the most appropriate execution plan.

---

# 2. Why Do Indexes Improve Performance?

Consider a table containing:

```text
10,000,000 orders
```

Suppose we want:

```sql
SELECT *
FROM orders
WHERE customer_id = 1250;
```

Without a suitable index, the database may need to inspect a very large portion of the table.

With an appropriate index, the database may be able to navigate directly toward the relevant part of the index and then access the matching rows.

Conceptually:

```text
Without index:

Table
 ↓
Scan many rows
 ↓
Check customer_id
 ↓
Return matches
```

With an index:

```text
Index
 ↓
Find customer_id = 1250
 ↓
Locate matching rows
 ↓
Access required table rows
 ↓
Return results
```

The exact execution depends on the optimizer, data distribution, query structure, and available indexes.

---

# 3. Indexes Have Costs

Indexes are not free.

Every additional index can introduce:

* Disk usage
* Additional memory/cache requirements
* INSERT maintenance
* UPDATE maintenance
* DELETE maintenance
* Index storage and maintenance overhead

For example:

```sql
INSERT INTO orders (...)
VALUES (...);
```

The database may need to update not only the table but also the relevant indexes.

Therefore:

```text
More indexes
      ↓
Potentially faster reads
      ↓
But also
      ↓
More write and storage overhead
```

### Professional rule

> Do not create indexes blindly.

The goal is not to maximize the number of indexes.

The goal is to create the **right indexes for the workload**.

---

# 4. Full Table Scan

A Full Table Scan means the database scans the table broadly to evaluate the query.

For example:

```sql
SELECT *
FROM orders
WHERE customer_id = 1250;
```

If there is no useful index, MySQL may perform:

```text
type: ALL
```

in an `EXPLAIN` plan.

`ALL` commonly indicates a Full Table Scan.

### Is Full Table Scan always bad?

No.

For a very small table, scanning the entire table may be cheaper than using an index.

Therefore, this is not a good rule:

> "Full Table Scan = bad."

A better professional question is:

> "Is the cost of this scan acceptable for this query and workload?"

This distinction is important in real-world database optimization.

---

# 5. EXPLAIN

`EXPLAIN` is one of the most important tools for SQL performance analysis.

Example:

```sql
EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 1250;
```

It shows the execution plan that MySQL's optimizer intends to use.

It can help answer questions such as:

* Is an index being considered?
* Which index is actually selected?
* What access method is being used?
* How many rows does the optimizer expect to examine?
* Is the query performing a full table scan?
* Is a JOIN using an appropriate access path?
* Are additional operations such as sorting required?

---

# 6. Important EXPLAIN Columns

Several `EXPLAIN` fields are especially important.

| Column          | Meaning                             |
| --------------- | ----------------------------------- |
| `possible_keys` | Indexes the optimizer may consider  |
| `key`           | Index actually selected             |
| `rows`          | Estimated number of rows to examine |
| `type`          | Access method                       |
| `Extra`         | Additional execution information    |

These fields are among the first things to inspect when diagnosing a slow query.

---

# 7. possible_keys

`possible_keys` shows indexes that the optimizer may consider for the query.

Example:

```text
possible_keys: idx_customer, idx_status
```

This does **not** mean both indexes are being used.

It only means they are possible candidates.

Therefore:

```text
possible_keys
      ↓
Candidate indexes
```

not:

```text
possible_keys
      ↓
Indexes actually used
```

---

# 8. key

`key` shows the index selected by the optimizer.

Example:

```text
possible_keys: idx_customer, idx_status
key: idx_customer
```

This means:

* `idx_customer` was considered as a possible index.
* The optimizer selected `idx_customer`.

### Important distinction

```text
possible_keys → What could be used?
key           → What was selected?
```

This distinction is important when reading real `EXPLAIN` output.

---

# 9. rows

The `rows` value is an **optimizer estimate**.

Example:

```text
rows: 500
```

This does not necessarily mean exactly 500 rows will be returned.

It means the optimizer estimates that approximately 500 rows may need to be examined/accessed for that plan step.

This distinction becomes particularly important when comparing:

```text
Estimated rows
```

with:

```text
Actual rows
```

using `EXPLAIN ANALYZE`.

---

# 10. EXPLAIN type

The `type` column describes the access method used for a table.

Important values include:

### ALL

Usually indicates a Full Table Scan.

```text
type: ALL
```

The database scans the table broadly.

---

### index

The database scans the index itself.

```text
type: index
```

An index scan is not automatically good.

Scanning an entire index may still be expensive.

---

### range

The database accesses an index over a range.

Example:

```sql
SELECT *
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date < '2026-02-01';
```

A possible plan may contain:

```text
type: range
```

---

### ref

Usually represents an indexed equality lookup where multiple matching rows may exist.

Example:

```sql
SELECT *
FROM orders
WHERE customer_id = 1250;
```

If `customer_id` has a non-unique index, a possible access type is:

```text
type: ref
```

---

### eq_ref

Typically appears in JOIN operations when the lookup uses a unique or primary key and can match at most one row per outer row.

---

### const

Typically used when MySQL can determine that at most one row can match, such as a primary key lookup.

Example:

```sql
SELECT *
FROM users
WHERE id = 150;
```

If `id` is the primary key, the access type may be:

```text
type: const
```

### Practical mental model

```text
const  → at most one matching row
eq_ref → unique/primary-key JOIN lookup
ref    → indexed lookup, potentially multiple rows
range  → indexed range
ALL    → broad/full table scan
```

Do not treat these values as an absolute performance ranking. The correct interpretation depends on the complete execution plan and workload.

---

# 11. Cardinality

Cardinality refers to the number of distinct values in a column.

Example:

Suppose `orders` contains 1,000,000 rows.

A `status` column may contain:

```text
completed
pending
cancelled
```

This means the column has very low cardinality.

On the other hand, `customer_id` might contain:

```text
400,000 different customers
```

which means it has much higher cardinality.

### Important

High cardinality does not automatically mean that an index is always useful.

The actual query predicate and data distribution still matter.

---

# 12. Selectivity

Selectivity describes how much a condition narrows the result set.

Suppose:

```text
1,000,000 total rows
```

Query:

```sql
WHERE customer_id = 1250
```

returns:

```text
5 rows
```

This predicate is highly selective.

However:

```sql
WHERE status = 'completed'
```

may return:

```text
900,000 rows
```

This predicate has poor selectivity for that workload.

### Cardinality vs Selectivity

These concepts must not be confused.

```text
Cardinality
→ How many distinct values does a column contain?

Selectivity
→ How much does a specific predicate narrow the data?
```

This distinction is important when evaluating index candidates.

---

# 13. B-Tree / B+Tree

B-Tree/B+Tree-style structures are fundamental to traditional MySQL/InnoDB indexing.

A useful mental model is a sorted directory.

Instead of checking every row one by one, the database can navigate through the tree toward the relevant key range.

Conceptually:

```text
Index
       ↓
Search tree
       ↓
Relevant key range
       ↓
Matching rows
```

This is one of the reasons indexes can significantly reduce the amount of data that needs to be examined.

---

# 14. Composite Indexes

A composite index contains multiple columns.

Example:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

The order is:

```text
1. customer_id
2. status
```

The order of columns is extremely important.

---

# 15. Leftmost Prefix Principle

Consider:

```sql
INDEX(customer_id, status)
```

This index is naturally useful for queries beginning with the leftmost column.

For example:

```sql
WHERE customer_id = 100;
```

and:

```sql
WHERE customer_id = 100
  AND status = 'completed';
```

are aligned with the index.

However:

```sql
WHERE status = 'completed';
```

does not naturally benefit from the same leftmost-prefix structure.

### Important

The order of conditions in the SQL statement is not the same as the order of columns in the index.

This:

```sql
WHERE status = 'completed'
  AND customer_id = 100;
```

can still use an index beginning with:

```text
(customer_id, status)
```

because SQL predicate order does not determine index column order.

The index structure and optimizer plan are what matter.

---

# 16. Composite Indexes and ORDER BY

Indexes are not only useful for `WHERE`.

They can also help with ordering.

Example:

```sql
SELECT *
FROM orders
WHERE customer_id = 100
ORDER BY order_date DESC
LIMIT 20;
```

A candidate index is:

```sql
CREATE INDEX idx_customer_date
ON orders(customer_id, order_date);
```

This allows the index to align with both:

```text
Filtering:
customer_id

Ordering:
order_date
```

This is an important real-world concept because many application queries look like:

```text
Find records
      ↓
Filter
      ↓
Sort
      ↓
Return first N rows
```

A well-designed composite index can reduce the amount of work required.

---

# 17. Equality → Range → Ordering

A useful starting heuristic for composite index design is:

```text
Equality
   ↓
Range
   ↓
Ordering
```

For example:

```sql
SELECT *
FROM orders
WHERE customer_id = 100
  AND status = 'completed'
  AND order_date >= '2026-01-01'
  AND order_date < '2026-02-01'
ORDER BY order_date DESC;
```

A natural candidate is:

```sql
CREATE INDEX idx_orders_search
ON orders(customer_id, status, order_date);
```

Conceptually:

```text
customer_id → equality
status      → equality
order_date  → range
```

### Important professional qualification

This is a **design heuristic**, not an absolute law.

Real index design must consider:

* Query shape
* Selectivity
* Data distribution
* Query frequency
* Sorting requirements
* JOIN conditions
* GROUP BY requirements
* Existing indexes
* Write workload
* Optimizer statistics

---

# 18. Workload-Based Index Design

This is one of the most important concepts for real-world SQL development.

Do not design indexes only by looking at the table structure.

Design them based on the **workload**.

Consider:

### Query A

```sql
SELECT *
FROM orders
WHERE customer_id = ?
  AND status = 'completed';
```

Executed:

```text
2,000,000 times/day
```

### Query B

```sql
SELECT *
FROM orders
WHERE customer_id = ?
ORDER BY order_date DESC
LIMIT 20;
```

Executed:

```text
50,000 times/day
```

If only one index can be created, Query A's frequency is an important factor.

A candidate could be:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

However, frequency alone is not enough.

Suppose Query B is extremely expensive and is part of a latency-critical API.

Then Query B may deserve priority despite running less frequently.

### Professional principle

> **Index design should be workload-driven, not table-driven.**

---

# 19. What Should Be Remembered for Real-World Work?

The following concepts are particularly important for professional SQL work.

## 19.1 Always Think About the Query Pattern

Do not ask only:

> "Which columns are important?"

Ask:

> "How are these columns used by real queries?"

For example:

```text
WHERE
JOIN
ORDER BY
GROUP BY
```

can all affect index design.

---

## 19.2 Do Not Assume Index Usage Means Good Performance

A query can use an index and still be slow.

For example:

* The index may return a huge number of rows.
* The query may require additional sorting.
* The query may perform many table lookups.
* The chosen index may not be optimal for the workload.

Therefore:

```text
Index exists
      ↓
Index is used
      ↓
Still analyze performance
```

---

## 19.3 Do Not Create an Index for Every WHERE Column

Suppose a table has:

```text
customer_id
status
order_date
country
payment_method
```

Creating five independent indexes without analyzing the workload is not automatically good design.

You may end up with:

* unnecessary storage
* higher write cost
* redundant indexes
* more maintenance

Index design should be evidence-based.

---

## 19.4 Consider Read vs Write Workload

For a read-heavy application, additional indexes may provide significant benefits.

For a write-heavy application, excessive indexes can become expensive.

Always consider:

```text
SELECT performance
        vs
INSERT / UPDATE / DELETE cost
```

---

# 20. Practical EXPLAIN Workflow

A useful workflow in real projects is:

```text
Slow query
    ↓
Run EXPLAIN
    ↓
Inspect execution plan
    ↓
Check key / type / rows / Extra
    ↓
Identify bottleneck
    ↓
Evaluate index or query rewrite
    ↓
Test the change
    ↓
Compare performance
```

The goal is not:

> "Make EXPLAIN look better."

The goal is:

> "Reduce the actual work required by the query while preserving correctness."

---

# 21. Common Mistakes

### Mistake 1

> "Every Full Table Scan is bad."

Not necessarily.

Small tables may be efficiently scanned.

---

### Mistake 2

> "If `possible_keys` contains my index, MySQL uses it."

Incorrect.

`possible_keys` contains candidates.

`key` shows the selected index.

---

### Mistake 3

> "`rows` tells me exactly how many rows the query returns."

Incorrect.

It is an optimizer estimate of rows to examine/access for that plan step.

---

### Mistake 4

> "Higher cardinality always means a better index."

Incorrect.

The query predicate, selectivity, data distribution, and workload matter.

---

### Mistake 5

> "More indexes always mean better performance."

Incorrect.

Indexes also increase storage and write-maintenance costs.

---

### Mistake 6

> "The order of WHERE conditions determines composite index order."

Incorrect.

The physical order of columns in the index is what matters.

---

### Mistake 7

> "An index is useful only for WHERE."

Incorrect.

Indexes can also support:

* JOIN
* ORDER BY
* GROUP BY
* covering access patterns

depending on the query and execution plan.

---

# 22. Must-Know Concepts

These are the concepts I should be able to explain without looking at documentation:

```text
1. What an index is
2. Why indexes improve reads
3. Why indexes increase write/maintenance cost
4. What a Full Table Scan is
5. How to use EXPLAIN
6. possible_keys vs key
7. What rows means
8. Meaning of important type values
9. Cardinality
10. Selectivity
11. Composite indexes
12. Leftmost prefix
13. Why composite index column order matters
14. Equality → Range → Ordering heuristic
15. Workload-based index design
16. Why index usage does not automatically mean good performance
```

---

# 23. Professional Mental Model

When looking at a slow query, think:

```text
What is the query trying to do?
        ↓
Which rows does it need?
        ↓
How selective is the condition?
        ↓
Can an index reduce the search space?
        ↓
Does the index also help JOIN / ORDER BY / GROUP BY?
        ↓
How many rows will still be accessed?
        ↓
What does EXPLAIN say?
        ↓
Is the index worth its write/storage cost?
        ↓
Does the change actually improve the workload?
```

This is much more useful than simply memorizing index syntax.

---

# 24. Key Takeaways

The most important lessons from Day 1 are:

> **1. An index provides an alternative access path to data.**

> **2. Indexes can make reads faster, but they introduce storage and write-maintenance costs.**

> **3. `EXPLAIN` is a fundamental tool for understanding query execution plans.**

> **4. `possible_keys` shows candidates; `key` shows the selected index.**

> **5. `rows` is an estimate, not necessarily the actual number of rows processed.**

> **6. Cardinality and selectivity are different concepts.**

> **7. Composite index column order matters because of the leftmost-prefix behavior.**

> **8. Index design should consider WHERE, JOIN, ORDER BY, GROUP BY, and the overall query pattern.**

> **9. Equality → Range → Ordering is a useful starting heuristic for composite indexes.**

> **10. Professional index design is workload-driven.**

---

# 25. Real-World Engineering Principle

The most important principle from this lesson is:

> **Do not optimize SQL by intuition alone. Measure, inspect the execution plan, understand the workload, make a targeted change, and verify the result.**

A professional SQL workflow is therefore:

```text
Query
  ↓
Measure
  ↓
EXPLAIN
  ↓
Understand
  ↓
Optimize
  ↓
Measure again
  ↓
Verify
```

This mindset will be used throughout the following query optimization topics.
