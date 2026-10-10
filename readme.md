# E-Commerce Analytics Portfolio Project

## Project Overview

This project uses SQL to analyze e-commerce customer purchasing behavior, customer segmentation, and product and category performance. The goal is to transform transactional data into meaningful business insights that can support data-driven decision-making.

## Tools and Technologies

* **MySQL** — data querying and analysis
* **MySQL Workbench** — database management and query execution

## Project Structure

* `ecommerce_analysis_dataSetup.sql` — database setup and data loading
* `ecommerce_analysis_queries.sql` — analytical SQL queries
* `README.md` — project documentation

## Dataset Overview

This project uses a generated, deterministic e-commerce dataset (seed = 42).

| Table | Number of Records |
| --- | ---: |
| Customers | 1,000 |
| Products | 51 |
| Categories | 10 |
| Orders | 5,000 |
| Order Items | 10,331 |
| Payments | 4,516 |

The order data covers **2024-01-01 to 2026-09-27**. RFM recency is evaluated using a fixed reference date of **2026-09-28**.

## Analysis Performed

### 1. Customer Analysis

* Analyzed customer spending and order activity.
* Examined the number of unique products and categories purchased by customers.
* Compared customer spending with purchasing behavior.

### 2. Customer Segmentation (RFM)

* Applied Recency, Frequency, and Monetary (RFM) analysis.
* Used SQL to group customers according to purchasing behavior and spending patterns.

### 3. Product & Category Analysis

* Evaluated product sales volume and revenue.
* Compared product and category performance.
* Used SQL ranking and segmentation techniques to classify products by sales volume and revenue.

## Key Findings

### Customer Spending and Product Variety

The analysis found a positive association between the variety of products customers purchased and their average recorded payment spending.

| Product Variety Segment | Customers | Average Recorded Spending | Average Orders |
| --- | ---: | ---: | ---: |
| Low Variety | 187 | $1,141.20 | 2.42 |
| Moderate Variety | 447 | $2,581.11 | 4.55 |
| High Variety | 361 | $4,602.47 | 6.82 |
| Very High Variety | 5 | $8,745.26 | 10.80 |

* High Variety customers spent approximately **4.03 times** as much on average as Low Variety customers.
* High Variety customers placed an average of **6.82 orders**, compared with **2.42** for Low Variety customers.
* The Very High Variety segment contained only **five customers**, so its average should be interpreted cautiously.
* These findings show an association, not causation. Differences in purchasing frequency may partly explain the spending gap.

### RFM Customer Segmentation

The RFM analysis assigned all **1,000 customers** to seven segments. **607 customers (60.7%)** fell into the At Risk or Lost Customers groups, while **81 customers (8.1%)** were Champions. Four customers had never purchased and were classified separately.

### Financial Metrics

* **Recorded payments:** $3,072,382.00, calculated from the `payments` table.
* **Product sales value:** $3,391,720.20, calculated from `quantity * unit_price` in `order_items`.

These figures measure different things and are not interchangeable with profit.

## SQL Skills Demonstrated

* Multi-table joins using `INNER JOIN` and `LEFT JOIN`
* Aggregate functions, including `SUM()`, `COUNT()`, and `AVG()`
* Common Table Expressions (CTEs) using `WITH`
* Conditional logic using `CASE`
* Customer segmentation using RFM analysis
* Window functions, including `NTILE()` and `LAG()`
* Revenue analysis and month-over-month comparisons
* Product performance ranking and categorization
* Data validation and handling missing payment records
* Separating customer spending metrics from product-level metrics to avoid double-counting

## Limitations

* Product sales value and recorded payment amounts represent different measures; neither is equivalent to profit.
* Product costs and profit margins are not included.
* 484 orders lack a recorded payment entry. This does not necessarily mean those orders were unpaid; missing records may affect payment-based spending metrics.
* The customer-segment findings are descriptive and do not establish causation.


