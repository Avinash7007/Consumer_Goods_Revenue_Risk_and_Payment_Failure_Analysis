# 📊 Consumer Goods Revenue Risk & Payment Failure Analysis  

An end-to-end **Consumer Goods Revenue Risk & Payment Failure Analysis** project focused on analyzing transactional data to understand revenue performance, cancellations, payment failures, returns, and operational trends across large-scale datasets.  
This project supports KPI monitoring and helps stakeholders improve visibility into revenue risk and payment realization patterns.

---

## 📌 Business Context

Consumer goods organizations often face revenue loss due to cancellations, failed payments, returns, and operational inefficiencies.  
This project analyzes transactional data to monitor revenue performance, identify operational patterns, and support reporting around financial risk exposure.

---

## 📦 Dataset Overview

| Table         | Description                          |
| ------------- | ------------------------------------ |
| Fact_Sales    | Orders, revenue, quantity, discount  |
| Fact_Shipment | Shipment and delivery performance    |
| Fact_Returns  | Return tracking and refunds          |
| Fact_Payments | Payment status and reconciliation    |
| Dim_Customer  | Customer master data                 |
| Dim_Product   | Product hierarchy                    |
| Dim_Region    | Regional segmentation                |
| Dim_Date      | Date dimension                       |

---

## 🎯 Key Business Metrics

| Metric               | Value     |
| -------------------- | --------- |
| Total Revenue        | ₹31.38 Cr |
| Avg Order Value      | ₹7,844    |
| Avg Discount         | 15%       |
| Return Rate          | 15%       |
| Cancellation Rate    | 33.5%     |
| Failed Payment Rate  | 33.5%     |
| Revenue at Risk      | ₹20.96 Cr |
| Net Realised Revenue | ₹10.42 Cr |

---

## ⚙️ Analysis Approach

- Initial validation using Excel (PivotTables + QA checks)  
- SQL-based transformation and reconciliation logic  
- KPI tracking using modular CTE-based workflows  
- Window functions for trend and cohort analysis  

---

## 🧮 Sample SQL Queries

### 🔹 Revenue at Risk Calculation
```sql
SELECT 
    SUM(CASE WHEN payment_status IN ('Failed','Pending') 
             THEN sales_amount ELSE 0 END) AS revenue_at_risk
FROM Fact_Payments;

### 🔹 Cancellation Rate Analysis
SELECT 
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 
    / COUNT(*) AS cancellation_rate
FROM Fact_Sales;

### 🔹 Running Revenue Trend
SELECT 
    order_date,
    SUM(daily_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM daily_sales;

```
---

## 🛠 Tech Stack

| Tool               | Usage                              |
| ------------------ | ---------------------------------- |
| SQL Server (T-SQL) | Core analytics queries             |
| SSMS               | Query development                  |
| Excel              | Validation and exploratory checks  |
| CTEs               | Modular business logic             |
| Window Functions   | Trend and cohort analysis          |
| CASE Expressions   | Customer segmentation              |

---

## 📂 Files

| File                        | Description       |
| --------------------------- | ----------------- |
| consumer-goods-analysis.sql | Full SQL analysis |
| README.md                   | Documentation     |

> Source dataset confidential — not shared publicly.

---

## 👤 Author

**Avinash Dubey — Data Analyst (≈3 YOE)**  

📧 dubeyavinash157@gmail.com  
🔗 https://www.linkedin.com/in/avinash7007/  
🌐 https://avinash7007.github.io/avinash-portfolio/  
🐙 https://github.com/Avinash7007
