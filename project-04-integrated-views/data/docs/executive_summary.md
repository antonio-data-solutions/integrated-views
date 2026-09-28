# Executive Summary - Project 04: Integrated Views

## Business Context
This project transforms raw e-commerce data (Olist) into an analytics-ready model, enabling fast, reliable insights on revenue, orders, customers, products, payments, sellers, and delivery performance.

## What Was Built
- End-to-end ETL pipeline (CSV → staging → dimensional model).
- Dimensional model with fact_sales and dimensions (time, customer, product, seller, payment).
- 8 analytical views covering key KPIs: monthly revenue & AOV, top customers/products, revenue by category/state/payment/seller, and on-time delivery rate.

## Why It Matters
- Demonstrates practical SQL skills (DDL, DML, views, modeling).
- Shows ability to turn raw data into business-ready analytics.
- Provides reusable patterns for real-world e-commerce dashboards.

## How to Reproduce
1. Create database `olist_db`.
2. Run `project-04-integrated-views.sql` (staging DDL, COPY, dimensional model, views).
3. Query the views (e.g., v_monthly_revenue, v_top_10_customers).

## Outcome
A clean, documented, and reproducible analytics solution ready to be showcased in a portfolio and adapted to real client datasets.