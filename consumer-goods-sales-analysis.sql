/*
===============================================================================
Consumer Goods Sales Analysis — SQL Script

Author   : Avinash Dubey
Role     : Data Analyst (≈3 YOE)
Database : Microsoft SQL Server (T-SQL)

-------------------------------------------------------------------------------
OVERVIEW
-------------------------------------------------------------------------------
End-to-end SQL analytics across 1L+ transactions covering:

• Revenue trends (YoY, QoQ, MoM, YTD)
• Order cancellations (33.5% rate analysis)
• Customer churn & retention
• Return root cause analysis
• Payment reconciliation (₹20.96 Cr at risk)
• Shipment performance
• Product & supplier contribution
• Customer segmentation (CLV + Pareto)

All queries are modular and can be executed section-wise.

-------------------------------------------------------------------------------
DATASET SNAPSHOT
-------------------------------------------------------------------------------
Fact_Sales      : 1,00,140 rows
Fact_Shipment   :   59,950 rows
Fact_Returns    :    9,037 rows
Fact_Payments   :   60,079 rows
Dim_Order       :   40,000 rows
Dim_Customer    :    5,000 rows
Dim_Product     :      500 rows
Dim_Region      :        4 rows
Dim_Supplier    :       50 rows
Dim_Date        :    1,461 rows (2022–2025)

-------------------------------------------------------------------------------
RUN ORDER
-------------------------------------------------------------------------------
1 — Data Validation
2 — Revenue Trends
3 — Order Cancellations
4 — Churn & Retention
5 — Returns
6 — Payments
7 — Shipment Performance
8 — Product & Supplier
9 — Customer Segmentation
===============================================================================
*/

USE db1;

--------------------------------------------------------------------------------
-- SECTION 1 — DATA VALIDATION
--------------------------------------------------------------------------------

-- Row count check
SELECT 'Fact_Sales' AS table_name, COUNT(*) FROM Fact_Sales UNION ALL
SELECT 'Fact_Shipment', COUNT(*) FROM Fact_Shipment UNION ALL
SELECT 'Fact_Returns', COUNT(*) FROM Fact_Returns UNION ALL
SELECT 'Fact_Payments', COUNT(*) FROM Fact_Payments;

-- NULL check
SELECT
SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS null_order_id,
SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS null_product_id
FROM Fact_Sales;

--------------------------------------------------------------------------------
-- SECTION 2 — REVENUE TRENDS
--------------------------------------------------------------------------------

-- Total revenue summary
SELECT
ROUND(SUM(Sales_Amount),2) AS total_revenue,
COUNT(DISTINCT Order_ID) AS total_orders,
ROUND(SUM(Sales_Amount)/NULLIF(COUNT(DISTINCT Order_ID),0),2) AS avg_order_value
FROM Fact_Sales;

-- YoY revenue growth
WITH yr_tab AS (
SELECT YEAR(Order_Date) yr, SUM(Sales_Amount) revenue
FROM Fact_Sales
GROUP BY YEAR(Order_Date)
)
SELECT yr, revenue,
LAG(revenue) OVER(ORDER BY yr) prev_year,
ROUND((revenue-LAG(revenue) OVER(ORDER BY yr))*100.0
/NULLIF(LAG(revenue) OVER(ORDER BY yr),0),2) yoy_pct
FROM yr_tab;

--------------------------------------------------------------------------------
-- SECTION 3 — ORDER CANCELLATIONS
--------------------------------------------------------------------------------

-- Cancellation rate by channel
SELECT
Order_Channel,
COUNT(*) total_orders,
SUM(CASE WHEN Order_Status='Cancelled' THEN 1 ELSE 0 END) cancelled,
ROUND(SUM(CASE WHEN Order_Status='Cancelled' THEN 1 ELSE 0 END)*100.0
/NULLIF(COUNT(*),0),2) cancel_rate_pct
FROM Dim_Order
GROUP BY Order_Channel;

-- Monthly cancellation trend (fixed)
SELECT
DATEFROMPARTS(YEAR(s.Order_Date),MONTH(s.Order_Date),1) yr_month,
COUNT(*) total_orders,
SUM(CASE WHEN o.Order_Status='Cancelled' THEN 1 ELSE 0 END) cancelled
FROM Dim_Order o
JOIN Fact_Sales s ON o.Order_ID=s.Order_ID
GROUP BY DATEFROMPARTS(YEAR(s.Order_Date),MONTH(s.Order_Date),1);

--------------------------------------------------------------------------------
-- SECTION 4 — CUSTOMER CHURN
--------------------------------------------------------------------------------

WITH last_order AS (
SELECT Customer_ID, MAX(Order_Date) last_order_date
FROM Fact_Sales
GROUP BY Customer_ID
)
SELECT *,
CASE
WHEN DATEDIFF(DAY,last_order_date,GETDATE())<90 THEN 'Active'
WHEN DATEDIFF(DAY,last_order_date,GETDATE())<=365 THEN 'At Risk'
ELSE 'Churned'
END status
FROM last_order;

--------------------------------------------------------------------------------
-- SECTION 5 — RETURNS
--------------------------------------------------------------------------------

SELECT
COUNT(DISTINCT s.Order_ID) total_orders,
COUNT(DISTINCT r.Order_ID) returned_orders,
ROUND(COUNT(DISTINCT r.Order_ID)*100.0/
NULLIF(COUNT(DISTINCT s.Order_ID),0),2) return_rate_pct
FROM Fact_Sales s
LEFT JOIN Fact_Returns r ON s.Order_ID=r.Order_ID;

--------------------------------------------------------------------------------
-- SECTION 6 — PAYMENTS
--------------------------------------------------------------------------------

SELECT
ROUND(SUM(Payment_Amount),2) gross_revenue,
ROUND(SUM(CASE WHEN Payment_Status='Completed'
THEN Payment_Amount ELSE 0 END),2) realised_revenue
FROM Fact_Payments;

--------------------------------------------------------------------------------
-- SECTION 7 — SHIPMENT PERFORMANCE
--------------------------------------------------------------------------------

SELECT
Ship_Mode,
ROUND(AVG(DATEDIFF(DAY,Ship_Date,Actual_Delivery_Date)),1) avg_delivery_days
FROM Fact_Shipment
GROUP BY Ship_Mode;

--------------------------------------------------------------------------------
-- SECTION 8 — PRODUCT PERFORMANCE
--------------------------------------------------------------------------------

SELECT TOP 10
p.Product_Name,
ROUND(SUM(s.Sales_Amount),2) revenue
FROM Fact_Sales s
JOIN Dim_Product p ON s.Product_ID=p.Product_ID
GROUP BY p.Product_Name
ORDER BY revenue DESC;

--------------------------------------------------------------------------------
-- SECTION 9 — CUSTOMER SEGMENTATION
--------------------------------------------------------------------------------

WITH clv AS (
SELECT Customer_ID, SUM(Sales_Amount) revenue
FROM Fact_Sales
GROUP BY Customer_ID
)
SELECT *,
CASE
WHEN revenue>=100000 THEN 'Platinum'
WHEN revenue>=50000 THEN 'Gold'
WHEN revenue>=20000 THEN 'Silver'
ELSE 'Regular'
END segment
FROM clv;

--------------------------------------------------------------------------------
-- END OF SCRIPT
--------------------------------------------------------------------------------