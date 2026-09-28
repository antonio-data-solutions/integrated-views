# Project 04 - Integrated Project with Views and Documentation

## Overview
This project implements an end-to-end analytics solution on top of the Brazilian E-Commerce (Olist) dataset. It covers data ingestion (ETL), dimensional modeling, and analytical views for key business KPIs.

## Dataset
- Source: Brazilian E-Commerce (Olist) - Kaggle
- Tables used: customers, geolocation, orders, order_items, order_payments, order_reviews, products, product_category_name_translation, sellers.

## KPIs Covered
- Monthly revenue and orders
- Average Order Value (AOV)
- Top 10 customers by revenue
- Top 10 products by revenue
- Revenue by product category
- Revenue by customer state
- Revenue by payment type
- Revenue by seller state
- Delivery on-time rate

## Dimensional Model
- Dimensions: dim_time, dim_customer, dim_product, dim_seller, dim_payment
- Fact table: fact_sales (one row per order item)

## Analytical Views
- v_monthly_revenue
- v_top_10_customers
- v_top_10_products
- v_revenue_by_category
- v_revenue_by_state
- v_revenue_by_payment_type
- v_revenue_by_seller_state
- v_delivery_performance

## How to Use
1. Create the database: `olist_db`.
2. Run the staging DDL to create staging tables.
3. Load CSVs into staging tables (COPY or pgAdmin Import/Export).
4. Run the dimensional model script to create dimensions and fact table.
5. Run the analytical views script to create KPI views.
6. Query the views to explore results.

## Author
Antonio [sobrenome]

## Project Status
Completed

## Copyright
Public domain / educational use.