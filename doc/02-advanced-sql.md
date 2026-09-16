# SQL Query Optimization — Day 2

## Overview

Day 2 focuses on understanding how SQL queries interact with indexes and how to identify inefficient query patterns.

The main topics are:

* `Using where`
* `Using filesort`
* `Using temporary`
* Covering Index
* Index Condition Pushdown (ICP)
* SARGable and non-SARGable predicates
* `LIKE` and index usage
* `OR`, `IN`, `!=`, and `NOT`
* JOIN optimization with indexes
* `EXPLAIN ANALYZE`
* Estimated vs actual execution behavior
* Query performance diagnosis

The main goal is to move from:

> "I know how indexes work."

to:

> "I can analyze why a query is slow and determine whether the query or index design should be changed."

---

# 1. `Using where`

`Using where` means that MySQL needs to apply a `WHERE` condition to filter rows.

Consider:

```sql
SELECT *
FROM orders
WHERE customer_id = 1250
  AND status = 'completed';
```

Suppose the table has:

```sql
CREATE INDEX idx_customer
ON orders(customer_id);
```

The index can help MySQL find rows for:

```text
customer_id = 1250
```

But `status` is not part of this index.

Conceptually:

```text
Index
  ↓
Find customer_id = 1250
  ↓
Access matching table rows
  ↓
Apply status = 'completed'
  ↓
Return results
```

The plan may contain:

```text
Extra: Using where
```

### Important

`Using where` does **not** mean:

> "MySQL performed a Full Table Scan."

The index may still be used.

It means that additional filtering is required.

### Professional mental model

> The index helps locate candidate rows; the remaining `WHERE` conditions may still need to be evaluated.

---

# 2. Why Index Structure Matters

Suppose we have:

```sql
CREATE INDEX idx_customer
ON orders(customer_id);
```

and:

```sql
WHERE customer_id = 1250
  AND status = 'completed';
```

The index only directly represents:

```text
customer_id
```

It does not contain:

```text
status
```

A possible improvement is:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

Now the index is better aligned with the filtering pattern.

The important principle is:

> The existence of an index is not enough. The index structure must match the query access pattern.

---

# 3. `Using filesort`

Consider:

```sql
SELECT *
FROM orders
WHERE customer_id = 1250
ORDER BY order_date DESC
LIMIT 20;
```

Suppose we only have:

```sql
CREATE INDEX idx_customer
ON orders(customer_id);
```

MySQL may find the customer's rows using the index.

However, it may still need to sort those rows according to:

```text
order_date DESC
```

The plan may contain:

```text
Extra: Using filesort
```

### What does filesort mean?

Despite its name, `filesort` does not necessarily mean that MySQL writes a physical file to disk.

It refers to MySQL's sorting mechanism.

Conceptually:

```text
Find matching rows
       ↓
Sort by order_date
       ↓
Return first 20
```

This can become expensive when many rows need to be sorted.

---

# 4. Avoiding Unnecessary Sorting

A composite index may better support the query:

```sql
CREATE INDEX idx_customer_date
ON orders(customer_id, order_date);
```

The index structure can align with:

```text
customer_id
     ↓
order_date
```

This can allow MySQL to retrieve matching rows in the required order without performing a separate sort in appropriate cases.

### Important

Do not memorize:

> "`Using filesort` = bad."

Instead ask:

* How many rows are being sorted?
* How often does the query run?
* Is the sorting expensive?
* Can an index support the required ordering?
* Is the optimization worth the additional index maintenance cost?

---

# 5. `Using temporary`

Consider:

```sql
SELECT customer_id, COUNT(*)
FROM orders
GROUP BY customer_id;
```

or:

```sql
SELECT customer_id, status, COUNT(*)
FROM orders
GROUP BY customer_id, status
ORDER BY COUNT(*) DESC;
```

MySQL may need an intermediate structure to process the query.

The plan may contain:

```text
Extra: Using temporary
```

Conceptually:

```text
orders
  ↓
GROUP BY
  ↓
Intermediate result
  ↓
COUNT
  ↓
ORDER BY
  ↓
Final result
```

### Important

`Using temporary` is not automatically a performance problem.

The correct question is:

> Why is a temporary structure needed, how much data is involved, and does it create a measurable bottleneck?

---

# 6. Covering Index

A covering index is an index that contains all the columns required by a particular query.

Consider:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

Query:

```sql
SELECT customer_id, status
FROM orders
WHERE customer_id = 100;
```

The query needs:

```text
customer_id
status
```

Both columns exist in the index.

Therefore, MySQL may be able to satisfy the query directly from the index without accessing the base table.

`EXPLAIN` may show:

```text
Extra: Using index
```

### Mental model

Normal access:

```text
Index
  ↓
Table
  ↓
Return data
```

Covering access:

```text
Index
  ↓
Return data
```

---

# 7. Covering Index Is Not a Separate Index Type

A common misunderstanding is:

> "I need to create a special covering index."

Not exactly.

A covering index is an **existing index that happens to contain all columns required by a particular query**.

For example:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

For:

```sql
SELECT customer_id, status
FROM orders
WHERE customer_id = 100;
```

this index can be covering.

But for:

```sql
SELECT customer_id, status, total_amount
FROM orders
WHERE customer_id = 100;
```

the index does not contain:

```text
total_amount
```

so it may not fully cover the query.

---

# 8. `SELECT *` and Covering Indexes

Consider:

```sql
SELECT *
FROM orders
WHERE customer_id = 100;
```

Even if:

```sql
INDEX(customer_id, status)
```

exists, the index normally does not contain every column required by `SELECT *`.

Therefore, the query generally needs access to the base table.

### Practical rule

If a query only needs a few columns, explicitly selecting those columns can sometimes make covering-index strategies possible.

Instead of:

```sql
SELECT *
```

consider:

```sql
SELECT customer_id, status
```

when those are actually the only required fields.

### Important

Do not add every column to an index just to avoid table access.

Large indexes can increase:

* storage usage
* memory pressure
* INSERT cost
* UPDATE cost
* DELETE cost

Covering indexes must be designed carefully.

---

# 9. Index Condition Pushdown (ICP)

Index Condition Pushdown is an optimization that allows MySQL to evaluate applicable index conditions as early as possible during index access.

Consider:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

and:

```sql
SELECT *
FROM orders
WHERE customer_id = 100
  AND status = 'completed';
```

Without effective early filtering:

```text
Index
  ↓
Candidate rows
  ↓
Table access
  ↓
WHERE filtering
```

With Index Condition Pushdown, MySQL may be able to evaluate relevant conditions during index access:

```text
Index
  ↓
Evaluate applicable index condition
  ↓
Reduce candidate rows
  ↓
Table access
  ↓
Return results
```

The goal is to reduce unnecessary table accesses.

---

# 10. `Using index` vs `Using index condition`

These two concepts must not be confused.

### `Using index`

Usually indicates that the query can be satisfied from the index itself.

```text
Index
 ↓
No base-table lookup required
```

This is associated with covering/index-only access.

### `Using index condition`

Indicates that an index condition is being evaluated during index access to reduce unnecessary table-row accesses.

```text
Index
 ↓
Filter applicable condition
 ↓
Table access for remaining required data
```

### Critical distinction

```text
Using index
→ The index can provide the required query data.

Using index condition
→ The index can help filter rows before table access.
```

ICP does not mean that the entire query is covered by the index.

---

# 11. SARGable Queries

SARGable is a very important concept in query optimization.

A predicate is considered SARGable when it is written in a form that allows the database to use an index efficiently for searching or range access.

Consider:

```sql
SELECT *
FROM orders
WHERE YEAR(order_date) = 2026;
```

The indexed column is wrapped inside a function:

```text
YEAR(order_date)
```

This can make direct index range access harder.

A more index-friendly form is:

```sql
SELECT *
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date < '2027-01-01';
```

Now the column itself is directly compared against a range.

Conceptually:

```text
Less index-friendly:
function(column)

More index-friendly:
column operator value
```

---

# 12. Another SARGable Example

Less index-friendly:

```sql
WHERE DATE(order_date) = '2026-05-10'
```

More index-friendly:

```sql
WHERE order_date >= '2026-05-10'
  AND order_date < '2026-05-11'
```

The second version defines a range directly on the indexed column.

### Professional rule

When optimizing a query, ask:

> "Am I applying a function or transformation to the indexed column unnecessarily?"

If yes, investigate whether the predicate can be rewritten into an index-friendly form.

### Important qualification

A function on a column does not mean an index can **never** be used.

The exact behavior depends on the database engine, version, query structure, and available indexes.

The important concept is:

> Functions applied to indexed columns can make efficient index access harder.

---

# 13. LIKE and Indexes

Consider:

```sql
WHERE name LIKE 'Arda%'
```

The known prefix is:

```text
Arda
```

A B-Tree index may be able to use this prefix for efficient range access.

However:

```sql
WHERE name LIKE '%Arda'
```

or:

```sql
WHERE name LIKE '%Arda%'
```

starts with a wildcard.

This makes normal B-Tree prefix searching much harder.

### Mental model

```text
'Arda%'
↓
Known beginning
↓
Index-friendly prefix search may be possible
```

Whereas:

```text
'%Arda%'
↓
Unknown beginning
↓
Efficient B-Tree prefix access is difficult
```

### Important

Do not use the absolute statement:

> "LIKE with `%` never uses an index."

The correct statement is:

> A leading wildcard makes efficient B-Tree index access difficult.

---

# 14. IN and Indexes

Consider:

```sql
SELECT *
FROM orders
WHERE customer_id IN (10, 20, 30);
```

`IN` can be index-friendly.

Conceptually, the database can perform multiple equality-style lookups.

```text
customer_id = 10
customer_id = 20
customer_id = 30
```

The exact execution plan depends on the optimizer and data distribution.

---

# 15. OR and Indexes

Consider:

```sql
WHERE customer_id = 10
   OR customer_id = 20
```

`OR` does not automatically mean that indexes cannot be used.

The optimizer may choose an appropriate strategy depending on:

* available indexes
* selectivity
* table size
* statistics
* query structure

Therefore:

> `OR` is not automatically bad.

Always inspect the execution plan before rewriting a query.

---

# 16. `!=` and `NOT`

Consider:

```sql
WHERE status != 'cancelled'
```

Suppose:

```text
completed = 900,000
pending   = 80,000
cancelled = 20,000
```

The condition:

```sql
status != 'cancelled'
```

matches:

```text
980,000 rows
```

This is a very large portion of the table.

An index may provide little benefit if the predicate is not selective enough.

Compare:

```sql
WHERE status = 'cancelled'
```

which matches only:

```text
20,000 rows
```

### Important principle

Index usefulness depends strongly on how much the condition narrows the search space.

---

# 17. JOIN and Index Optimization

Indexes are very important for JOIN performance.

Consider:

```sql
SELECT c.name, o.total_amount
FROM customers c
JOIN orders o
    ON c.id = o.customer_id;
```

Usually:

```text
customers.id
```

is a primary key and therefore already indexed.

The important candidate is often:

```sql
CREATE INDEX idx_orders_customer
ON orders(customer_id);
```

Why?

During the JOIN, the database needs to find matching rows in:

```text
orders.customer_id
```

The index can provide a faster lookup path.

### Important wording

Do not think:

> "The JOIN itself is indexed."

Instead think:

> "The columns used for matching rows in the JOIN can be indexed."

---

# 18. JOIN + WHERE

Consider:

```sql
SELECT c.name, o.total_amount
FROM customers c
JOIN orders o
    ON c.id = o.customer_id
WHERE o.status = 'completed';
```

A candidate composite index is:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

The index can align with both:

```text
JOIN:
customer_id

Filter:
status
```

However, the correct index cannot be determined from syntax alone.

We should consider:

* cardinality
* selectivity
* query frequency
* data distribution
* JOIN order
* optimizer statistics
* other workload queries

---

# 19. Why Index Column Order Matters in JOINs

Suppose:

```text
5,000,000 orders
```

and:

```text
completed = 4,500,000
pending   = 400,000
cancelled = 100,000
```

`status` has relatively low selectivity when filtering:

```sql
WHERE status = 'completed'
```

because it matches 4.5 million rows.

Meanwhile:

```text
customer_id
```

may contain approximately 400,000 distinct customers.

For a JOIN such as:

```sql
ON customers.id = orders.customer_id
```

an index beginning with:

```text
customer_id
```

can be a strong candidate.

For example:

```sql
INDEX(customer_id, status)
```

may be more appropriate than:

```sql
INDEX(status, customer_id)
```

for this particular workload.

### Important

This is not a universal rule that:

> "High-cardinality columns must always come first."

The correct decision depends on the complete query and workload.

---

# 20. Creating Indexes on a Table

When creating an index, the table is already specified:

```sql
CREATE INDEX idx_customer_status
ON orders(customer_id, status);
```

There is no need to write:

```sql
CREATE INDEX idx_customer_status
ON orders(orders.customer_id, orders.status);
```

The syntax:

```text
ON orders(...)
```

already establishes the table context.

---

# 21. EXPLAIN ANALYZE

`EXPLAIN` and `EXPLAIN ANALYZE` serve different purposes.

### EXPLAIN

Primarily shows the optimizer's planned execution strategy and estimates.

```sql
EXPLAIN
SELECT ...
```

### EXPLAIN ANALYZE

Actually executes the query and provides measured execution information.

```sql
EXPLAIN ANALYZE
SELECT ...
```

This allows us to compare:

```text
Estimated behavior
        vs
Actual behavior
```

---

# 22. Why Use EXPLAIN ANALYZE?

Suppose `EXPLAIN` says:

```text
rows = 100
```

but `EXPLAIN ANALYZE` shows:

```text
actual rows = 50,000
```

There is a significant difference between the optimizer's estimate and reality.

This can help explain unexpected query performance.

### Professional workflow

```text
Slow query
   ↓
EXPLAIN
   ↓
Understand the plan
   ↓
Identify suspicious estimates/access paths
   ↓
EXPLAIN ANALYZE
   ↓
Measure actual behavior
   ↓
Optimize
   ↓
Measure again
```

---

# 23. Does EXPLAIN ANALYZE Slow the System?

Yes, while it is running.

Unlike a plain `EXPLAIN`, `EXPLAIN ANALYZE` actually executes the query.

Therefore it consumes resources such as:

* CPU
* memory
* I/O
* execution time

On a very large query or production database, this can create noticeable load.

However:

> It does not permanently reduce system performance.

The resource consumption occurs while the query is being executed and measured.

### Production mindset

Be careful when running expensive `EXPLAIN ANALYZE` statements against large production datasets.

---

# 24. actual time

An `EXPLAIN ANALYZE` result may contain information such as:

```text
actual time=0.05..3.20
```

This represents measured execution timing for that operation.

It is fundamentally different from optimizer `cost`.

---

# 25. cost

Consider:

```text
cost=120.50
```

This is **not**:

```text
120.50 milliseconds
```

and not:

```text
120.50 MB
```

It is an internal optimizer cost estimate used to compare execution strategies.

The optimizer may consider factors such as:

* row access
* index access
* storage operations
* CPU work
* JOIN operations
* estimated processing effort

### Critical distinction

```text
cost
→ estimated internal optimizer cost

actual time
→ measured execution time
```

---

# 26. actual rows

Example:

```text
actual rows=8,000
```

This represents the actual number of rows produced by that plan operation per loop.

It can be compared with the optimizer's estimate.

For example:

```text
estimated rows = 10
actual rows    = 8,000
```

This is a significant mismatch.

Such a mismatch may indicate that the optimizer's assumptions or statistics do not accurately represent the data distribution.

---

# 27. loops

Example:

```text
loops=5,000
```

means that the operation was executed 5,000 times.

This is particularly important in JOINs.

Conceptually:

```text
Outer rows
   ↓
Inner lookup
   ↓
Repeated many times
```

If an inner operation is repeated thousands of times, its efficiency becomes extremely important.

An appropriate index can make each repeated lookup much cheaper.

### Important qualification

Do not automatically interpret:

```text
actual rows × loops
```

as the number of unique final result rows.

It is better understood as an indication of repeated work performed by that plan node.

---

# 28. Understanding JOIN Loops

Suppose a JOIN produces:

```text
loops = 5,000
```

This does not automatically mean:

> "The entire inner table was scanned 5,000 times."

If the inner operation is an index lookup, the database may perform targeted lookups repeatedly.

Conceptually:

```text
Outer row 1 → index lookup
Outer row 2 → index lookup
Outer row 3 → index lookup
...
Outer row 5000 → index lookup
```

This is very different from:

```text
Outer row 1 → Full Table Scan
Outer row 2 → Full Table Scan
...
```

The second situation can be extremely expensive.

### Professional insight

> In JOIN optimization, the cost of the inner access path matters because it may be executed repeatedly.

---

# 29. Functional Correctness vs Performance Correctness

This distinction is important in professional development.

### Functional correctness

Question:

> "Does the query return the correct business result?"

Example:

```text
Are the correct customer orders returned?
```

This is verified using tests and validation.

### Performance correctness

Question:

> "Does the query return the correct result within acceptable resource and latency limits?"

Tools include:

* `EXPLAIN`
* `EXPLAIN ANALYZE`
* profiling
* monitoring
* benchmarking

A query can be functionally correct and still be unacceptable in production because it takes too long or consumes too many resources.

---

# 30. Important Performance Mental Model

When analyzing a query, think in this order:

```text
1. What result does the query need?
            ↓
2. Which rows must be found?
            ↓
3. Can an index reduce the search space?
            ↓
4. Does the index support filtering?
            ↓
5. Does it support JOIN conditions?
            ↓
6. Does it support ordering?
            ↓
7. How many rows are accessed?
            ↓
8. Is additional sorting/filtering required?
            ↓
9. What does EXPLAIN ANALYZE actually show?
            ↓
10. Is the optimization worth its maintenance cost?
```

This is the mindset expected from someone working with production databases.

---

# 31. Must-Know Concepts

These concepts should be understood well enough to explain without documentation:

```text
1. Using where
2. Using filesort
3. Using temporary
4. Covering Index
5. Using index
6. Index Condition Pushdown
7. Using index condition
8. SARGable predicates
9. Leading wildcard and LIKE
10. IN and index usage
11. OR and optimizer behavior
12. Selectivity of != / NOT conditions
13. JOIN + index optimization
14. EXPLAIN ANALYZE
15. Estimated vs actual rows
16. actual time
17. cost
18. loops
19. Repeated JOIN lookups
20. Functional correctness vs performance correctness
```

---

# 32. Critical Distinctions

These distinctions are especially important in real-world SQL work.

### `Using where` vs Full Table Scan

```text
Using where
→ Additional filtering is required.

Full Table Scan
→ Broad table access is being performed.
```

They are not the same thing.

---

### `Using index` vs `Using index condition`

```text
Using index
→ Query can be satisfied from the index.

Using index condition
→ Index condition is evaluated early to reduce table access.
```

---

### EXPLAIN vs EXPLAIN ANALYZE

```text
EXPLAIN
→ Plan + estimates

EXPLAIN ANALYZE
→ Execute + measure actual behavior
```

---

### cost vs actual time

```text
cost
→ Optimizer's internal estimate

actual time
→ Real measured execution time
```

---

### Cardinality vs Selectivity

```text
Cardinality
→ Number of distinct values

Selectivity
→ How much a predicate narrows the result set
```

---

# 33. Common Mistakes to Avoid

### Mistake 1

> "`Using filesort` always means the query is bad."

Incorrect.

You need to know how much data is being sorted and whether it is actually a bottleneck.

---

### Mistake 2

> "`Using temporary` means the database is broken."

Incorrect.

Temporary structures can be a normal part of query execution.

---

### Mistake 3

> "Covering index is a special index type."

Incorrect.

A covering index is an existing index that contains all columns required by a particular query.

---

### Mistake 4

> "ICP means the query is fully covered."

Incorrect.

ICP reduces unnecessary table access by evaluating applicable conditions during index access.

---

### Mistake 5

> "A function on an indexed column always disables the index."

Too absolute.

Functions can make efficient index access harder, but exact behavior depends on the engine and query.

---

### Mistake 6

> "`LIKE '%text%'` can efficiently use a normal B-Tree index."

Usually incorrect.

A leading wildcard makes normal B-Tree prefix access difficult.

---

### Mistake 7

> "`OR` always prevents index usage."

Incorrect.

The optimizer may still use indexes depending on the query and data.

---

### Mistake 8

> "`!=` always means an index cannot be used."

Incorrect.

The important issue is selectivity and the cost of the chosen plan.

---

### Mistake 9

> "JOIN means the entire second table is scanned."

Incorrect.

With a suitable index, the inner side can be accessed through targeted lookups.

---

### Mistake 10

> "`EXPLAIN ANALYZE` only checks whether the SQL syntax is correct."

Incorrect.

Its primary value is measuring actual execution behavior and comparing it with the optimizer's estimates.

---

# 34. Real-World SQL Optimization Workflow

A practical production-oriented workflow is:

```text
                    Slow Query
                        ↓
                  Reproduce Issue
                        ↓
                      EXPLAIN
                        ↓
             Understand Execution Plan
                        ↓
          ┌─────────────┴─────────────┐
          ↓                           ↓
     Query Problem                Index Problem
          ↓                           ↓
    Rewrite Query              Design/Test Index
          └─────────────┬─────────────┘
                        ↓
                 EXPLAIN ANALYZE
                        ↓
                 Measure Results
                        ↓
                  Compare Before/After
                        ↓
               Validate Correctness
                        ↓
                 Deploy Carefully
```

This process is far more valuable than blindly adding indexes.

---

# 35. Day 2 Professional Takeaways

The most important ideas from this day are:

> **1. An index being used does not automatically mean the query is efficient.**

> **2. `Using where` means additional filtering is being performed; it does not mean Full Table Scan.**

> **3. `Using filesort` indicates an additional sorting operation; its impact depends on the amount of data and workload.**

> **4. `Using temporary` means MySQL may use an intermediate structure; it is not automatically a problem.**

> **5. A covering index can allow a query to be satisfied entirely from the index.**

> **6. ICP can reduce unnecessary table access by evaluating applicable conditions during index access.**

> **7. SARGable predicates allow the database to use indexes more effectively.**

> **8. Leading wildcards in `LIKE` make efficient B-Tree access difficult.**

> **9. JOIN columns are important index candidates because JOIN lookups may be repeated many times.**

> **10. `EXPLAIN ANALYZE` is used to compare optimizer estimates with actual execution behavior.**

> **11. `cost` is an optimizer estimate; `actual time` is measured execution time.**

> **12. `loops` is especially important when analyzing repeated JOIN operations.**

> **13. Query optimization should be based on measurement, not intuition alone.**

---

# 36. What I Should Be Able to Do After Day 2

After completing these topics, I should be able to look at a query and ask:

```text
Is the query SARGable?
        ↓
Can an index help?
        ↓
Is the existing index aligned with the query?
        ↓
Can the index help filtering?
        ↓
Can it help JOIN?
        ↓
Can it help ORDER BY?
        ↓
Can the query become covering?
        ↓
Is additional sorting required?
        ↓
Is additional filtering required?
        ↓
How many rows are actually processed?
        ↓
How many times is an operation repeated?
        ↓
Does EXPLAIN ANALYZE confirm the expected behavior?
```

That is the transition from learning SQL syntax to performing **real SQL performance analysis**.

---

# 37. Final Engineering Principle

The most important lesson from Day 2 is:

> **Do not optimize a query because something "looks bad." Identify the actual work being performed, measure it, understand the execution plan, make a targeted change, and measure again.**

A strong SQL engineer does not simply know:

```text
CREATE INDEX
```

They know:

```text
Why should this index exist?
What query does it optimize?
How selective is the predicate?
How often does the query run?
What is the read benefit?
What is the write cost?
What does EXPLAIN show?
What does EXPLAIN ANALYZE show?
Did the optimization actually improve performance?
```

That is the knowledge that transfers directly to real-world database engineering.
