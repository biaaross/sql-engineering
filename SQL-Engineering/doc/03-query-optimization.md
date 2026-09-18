# SQL Engineering — Day 3

## Index Maintenance and Index Lifecycle Management

## 1. Overview

This section focuses on **Index Maintenance**, which is the process of evaluating, managing, and optimizing indexes based on real query workloads.

Creating indexes is only one part of database optimization. In real systems, indexes must also be reviewed to determine whether they provide enough performance benefit to justify their storage and maintenance costs.

The main principle is:

> **An index should be evaluated based on workload, not only on whether it exists.**

---

# 2. Index Maintenance

Indexes improve read performance, but they also introduce additional costs.

Every index can affect:

* SELECT performance
* INSERT performance
* UPDATE performance
* DELETE performance
* Storage usage
* Memory/cache usage
* Index maintenance overhead

Therefore, having more indexes does not automatically mean better performance.

A database should contain indexes that provide meaningful value for the actual workload.

---

# 3. Index Maintenance Costs

Consider the following index:

```sql
CREATE INDEX idx_customer
ON orders(customer_id);
```

When a query searches by `customer_id`, the index may significantly improve read performance.

However, when a new order is inserted:

```sql
INSERT INTO orders (...)
VALUES (...);
```

the database must also maintain the related index structure.

Conceptually:

```text
INSERT
   ↓
Table update
   +
Index maintenance
```

The same principle applies to updates and deletes.

---

## 3.1 INSERT Cost

When a row is inserted, relevant indexes may also need to be updated.

Therefore:

> More indexes can mean more work during INSERT operations.

This becomes especially important in systems with high write workloads.

---

## 3.2 UPDATE Cost

If an indexed column changes, the corresponding index structure may need to be updated.

For example:

```sql
UPDATE orders
SET status = 'completed'
WHERE id = 1000;
```

If `status` participates in one or more indexes, those indexes may require maintenance.

---

## 3.3 DELETE Cost

When a row is deleted, corresponding entries must also be removed from relevant indexes.

Therefore, indexes can increase the cost of write-heavy workloads.

---

# 4. Index Storage Cost

Indexes require disk space.

For example:

```text
Table:
5 GB

Indexes:
3 GB
```

The exact size depends on the table structure, indexed columns, data types, and index design.

Large tables can therefore have significant index storage requirements.

Index size can also affect memory/cache usage because frequently accessed index pages may compete for available memory.

---

# 5. Duplicate Indexes

A **duplicate index** occurs when two indexes have the same indexed columns in the same order.

Example:

```sql
CREATE INDEX idx_customer
ON orders(customer_id);

CREATE INDEX idx_customer_2
ON orders(customer_id);
```

Both indexes represent the same indexed column structure:

```text
idx_customer
(customer_id)

idx_customer_2
(customer_id)
```

The second index normally does not provide an additional access path.

However, it can still introduce:

* Additional storage usage
* Additional index maintenance
* Extra work during INSERT, UPDATE, and DELETE

Therefore, duplicate indexes are usually candidates for removal after proper verification.

---

# 6. Redundant Indexes

A **redundant index** is different from a duplicate index.

Example:

```sql
INDEX(customer_id);

INDEX(customer_id, status);
```

These indexes are not identical.

The second index starts with `customer_id` and can support many queries that search using the leftmost `customer_id` column.

Therefore, the single-column index may be redundant depending on the workload.

However, it should not automatically be removed.

The decision should be based on:

* Actual query workload
* Index usage
* Query frequency
* Query performance
* Write workload
* Business-critical queries
* Execution plans

---

# 7. Duplicate vs. Redundant Index

### Duplicate

```text
INDEX(customer_id)
INDEX(customer_id)
```

The indexes are effectively identical.

### Redundant

```text
INDEX(customer_id)
INDEX(customer_id, status)
```

The indexes are different, but the second index may already provide the access path needed by many queries using `customer_id`.

Key distinction:

> **Duplicate indexes are identical. Redundant indexes overlap in functionality.**

---

# 8. Too Many Indexes

A common database design mistake is creating an index for every query that appears to be slow.

For example:

```text
idx_customer
idx_status
idx_order_date
idx_total_amount
idx_customer_status
idx_customer_date
idx_status_date
idx_customer_status_date
```

Having many indexes may look beneficial, but every additional index introduces potential maintenance and storage costs.

The goal is not:

> "Create as many indexes as possible."

The goal is:

> **Create and keep the indexes that provide meaningful value for the workload.**

---

# 9. Unused Indexes

An **unused index** is an index that is not being used by the workload, or is used very rarely.

For example:

```sql
CREATE INDEX idx_total_amount
ON orders(total_amount);
```

If no important query uses this index, it may provide little or no read benefit.

However, the index can still introduce:

* Storage cost
* Maintenance cost
* Write overhead

Therefore, an unused index may become a candidate for removal.

---

# 10. Unused Does Not Automatically Mean Unnecessary

This is an important real-world distinction.

An index may appear unused during a short observation period but still be important.

For example:

```text
Daily queries:
0

Monthly financial report:
1
```

If the monthly report depends on the index and is business-critical, removing the index could be a mistake.

Therefore:

> **An index should not be removed simply because it was not used recently.**

The observation period and workload must be considered.

---

# 11. Evaluating an Index Before Removing It

Before removing an index, consider:

### 1. Is the index being used?

Frequent usage is strong evidence that the index provides value.

### 2. Is it rarely used?

Rare usage requires further investigation.

### 3. Is it used by a critical query?

A query can be rare but still business-critical.

### 4. Is another index already providing the same functionality?

This is especially important when evaluating redundant indexes.

### 5. How expensive is the index to maintain?

Write-heavy tables make unnecessary indexes more costly.

### 6. How much storage does the index consume?

Large indexes can have significant storage and cache implications.

---

# 12. Workload-Based Index Cleanup

Index maintenance should be based on the actual workload.

Consider:

```text
orders
50 million rows
```

with:

```text
idx_customer
idx_status
idx_order_date
idx_total_amount
idx_customer_status
idx_customer_date
```

Suppose the workload is approximately:

```text
customer_id queries
→ 5 million/day

order_date queries
→ 2 million/day

status queries
→ 1 million/day

total_amount queries
→ almost none
```

The `idx_total_amount` index becomes a candidate for further investigation.

However, the correct approach is not:

> "It is unused, so delete it."

Instead, evaluate:

```text
Index usage
+
Query frequency
+
Business importance
+
Read benefit
+
Write cost
+
Storage cost
+
Overlap with other indexes
```

Then decide whether to:

```text
KEEP
MODIFY
REMOVE
```

---

# 13. Index Lifecycle

A professional index lifecycle can be viewed as:

```text
Workload
   ↓
Query analysis
   ↓
Index design
   ↓
Performance measurement
   ↓
Production usage
   ↓
Usage monitoring
   ↓
Maintenance
   ↓
Keep / Modify / Remove
```

Indexes should therefore be treated as part of the database's evolving workload rather than as permanent objects that are created once and forgotten.

---

# 14. Professional Index Optimization Workflow

A practical workflow is:

```text
1. Identify important queries
        ↓
2. Analyze execution plans
        ↓
3. Identify useful indexes
        ↓
4. Measure performance
        ↓
5. Monitor index usage
        ↓
6. Identify duplicate/redundant indexes
        ↓
7. Identify potentially unused indexes
        ↓
8. Evaluate read benefit vs. maintenance cost
        ↓
9. Remove or modify unnecessary indexes
        ↓
10. Measure again
```

The key idea is that index optimization is an iterative process.

---

# 15. Important Professional Principle

Index optimization is not simply about creating indexes.

A strong SQL engineer should be able to answer both:

> **"Which index should I create?"**

and:

> **"Which index should I remove, and why?"**

This requires understanding:

* Query workload
* Selectivity
* Composite indexes
* Execution plans
* Read performance
* Write performance
* Storage costs
* Business requirements

---

# 16. Common Mistakes

### Mistake 1: More indexes always mean better performance

False.

More indexes can improve some reads but increase write and storage costs.

### Mistake 2: Unused index means immediately delete it

Not necessarily.

The index may support an important but infrequent query.

### Mistake 3: Duplicate and redundant indexes are the same

They are not.

```text
Duplicate:
INDEX(customer_id)
INDEX(customer_id)
```

```text
Redundant:
INDEX(customer_id)
INDEX(customer_id, status)
```

### Mistake 4: Index maintenance only matters for SELECT

False.

Indexes can affect:

```text
INSERT
UPDATE
DELETE
```

as well.

### Mistake 5: Index decisions should be based on the table alone

Index decisions should be based on the actual workload and query patterns.

---

# 17. Must-Know Concepts

The following concepts should be understood before moving to practical performance work:

1. Index maintenance
2. Index write cost
3. Index storage cost
4. Duplicate indexes
5. Redundant indexes
6. Too many indexes
7. Unused indexes
8. Index usage monitoring
9. Workload-based index cleanup
10. Read benefit vs. write cost
11. Business-critical queries
12. Index lifecycle management
13. Keep / Modify / Remove decisions

---

# 18. Key Takeaways

* Indexes improve read performance but introduce costs.
* INSERT, UPDATE, and DELETE operations may require index maintenance.
* Indexes consume storage.
* Duplicate indexes provide overlapping access paths and are usually unnecessary.
* Redundant indexes overlap in functionality and require workload-based evaluation.
* Too many indexes can negatively affect write-heavy workloads.
* An unused index is a candidate for investigation, not automatically for deletion.
* Index removal should consider workload, business importance, performance, storage, and maintenance cost.
* Index design should be based on real query workloads.
* Index maintenance is an ongoing process, not a one-time task.

---

# 19. Final Engineering Principle

> **Good database optimization is not about having the most indexes. It is about having the right indexes for the workload.**

The professional approach is:

```text
Measure
   ↓
Analyze
   ↓
Design
   ↓
Optimize
   ↓
Monitor
   ↓
Maintain
```

This completes the theoretical part of query optimization and prepares the foundation for practical SQL performance analysis.
