# E-Commerce Analytics

A practical SQL analytics project built around a relational e-commerce database.

The project focuses on analyzing customers, products, orders, and sales data using SQL.

## Project Objective

The goal of this project is to answer realistic business questions using SQL and demonstrate practical skills in:

* Relational database design
* Data analysis
* Complex SQL queries
* Aggregation
* JOINs
* CTEs
* Subqueries
* Window functions
* Date-based analysis
* Customer analysis
* Product analysis
* Sales analysis

The project is designed to demonstrate how SQL can be used to transform raw transactional data into useful business insights.

## Database Structure

The database contains four main tables:

```text
customers
    │
    │ 1:N
    ↓
orders
    │
    │ 1:N
    ↓
order_items
    │
    │ N:1
    ↓
products
```

### Customers

Stores customer information.

Main fields:

* `id`
* `name`
* `email`
* `country`
* `created_at`

### Products

Stores information about products sold by the company.

Main fields:

* `id`
* `name`
* `category`
* `price`
* `created_at`

### Orders

Stores customer orders.

Main fields:

* `id`
* `customer_id`
* `status`
* `order_date`

### Order Items

Stores the products included in each order.

Main fields:

* `id`
* `order_id`
* `product_id`
* `quantity`
* `unit_price`

The `unit_price` column represents the product price at the time of purchase, allowing historical order values to remain accurate even if the current product price changes.

## Project Questions

The project will investigate realistic business questions such as:

### Customer Analysis

* Which customers have spent the most?
* How many orders has each customer placed?
* What is the average order value per customer?
* Which customers have the highest number of completed orders?
* Which customers have not made a recent purchase?

### Sales Analysis

* What is the total revenue?
* What is the average order value?
* How does revenue change over time?
* How many orders exist for each status?
* Which orders have the highest total value?

### Product Analysis

* Which products are sold the most?
* Which products generate the most revenue?
* Which product categories generate the highest revenue?
* What is the total quantity sold for each product?
* How do products rank within their categories?

### Monthly Analysis

* What is the monthly revenue?
* How does each month compare with the previous month?
* Which month generated the highest revenue?
* How does sales performance change over time?

## SQL Concepts Applied

The project will apply the following SQL concepts:

* SELECT
* WHERE
* GROUP BY
* HAVING
* ORDER BY
* JOIN
* Subqueries
* CTEs
* CASE
* Aggregate Functions
* Window Functions
* `ROW_NUMBER()`
* `DENSE_RANK()`
* `LAG()`
* Date Functions
* Transactions
* Indexing
* Query Optimization

Only concepts that are appropriate for a particular problem will be used. The goal is to solve problems effectively rather than force every SQL feature into every query.

## Project Structure

```text
ecommerce-analytics/
│
├── README.md
├── schema.sql
├── data.sql
│
├── queries/
│   ├── customer-analysis.sql
│   ├── sales-analysis.sql
│   ├── product-analysis.sql
│   └── monthly-analysis.sql
│
└── analysis.md
```

## Database

MySQL

## Workflow

The project follows a practical data-analysis workflow:

```text
Database Design
      ↓
Data Generation
      ↓
Business Question
      ↓
SQL Query
      ↓
Result
      ↓
Analysis
```

## Goal

The purpose of this project is to demonstrate practical SQL problem-solving skills through a realistic e-commerce dataset.

The project emphasizes writing clear and meaningful SQL queries, analyzing relational data, and translating business questions into data-driven answers.
