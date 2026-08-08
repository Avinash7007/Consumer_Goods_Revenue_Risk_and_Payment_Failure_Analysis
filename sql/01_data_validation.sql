/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        01_data_validation.sql

    Purpose:
        Validate SQL Server staging data before business analysis.

    Source Tables:
        dbo.stg_customers
        dbo.stg_orders
        dbo.stg_payments

    Technology:
        SQL Server / T-SQL

    Important:
        This script is READ-ONLY.
        It does not modify or delete source data.

    Approved Project Metrics:
        Total Orders          = 40,000
        Cancelled Orders      = 13,381
        Cancellation Rate     = 33.45%
        Revenue Loss          = 2.5M
        At-Risk Customers     = 2,389
        Churn Definition      = 90 Days Inactivity
*/

USE YOUR_DATABASE_NAME;
GO

/* ============================================================
   1. BASIC TABLE ROW COUNTS
   ============================================================ */

SELECT 'stg_customers' AS TableName, COUNT(*) AS RowCount
FROM dbo.stg_customers
UNION ALL
SELECT 'stg_orders', COUNT(*)
FROM dbo.stg_orders
UNION ALL
SELECT 'stg_payments', COUNT(*)
FROM dbo.stg_payments;
GO

/* ============================================================
   2. CUSTOMER TABLE — NULL CHECK
   ============================================================ */
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS MissingCustomerIDs
FROM dbo.stg_customers;
GO

/* ============================================================
   3. CUSTOMER TABLE — DUPLICATE CUSTOMER IDs
   ============================================================ */
SELECT customer_id, COUNT(*) AS DuplicateCount
FROM dbo.stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;
GO

/* ============================================================
   4. ORDER TABLE — REQUIRED FIELD VALIDATION
   ============================================================ */
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS MissingOrderIDs,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS MissingCustomerIDs,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS MissingOrderDates
FROM dbo.stg_orders;
GO

/* ============================================================
   5. ORDER TABLE — DUPLICATE ORDER IDs
   ============================================================ */
SELECT order_id, COUNT(*) AS DuplicateCount
FROM dbo.stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;
GO

/* ============================================================
   6. PAYMENT TABLE — REQUIRED FIELD VALIDATION
   ============================================================ */
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN payment_id IS NULL THEN 1 ELSE 0 END) AS MissingPaymentIDs,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS MissingOrderIDs,
    SUM(CASE WHEN payment_date IS NULL THEN 1 ELSE 0 END) AS MissingPaymentDates
FROM dbo.stg_payments;
GO

/* ============================================================
   7. PAYMENT TABLE — DUPLICATE PAYMENT IDs
   ============================================================ */
SELECT payment_id, COUNT(*) AS DuplicateCount
FROM dbo.stg_payments
GROUP BY payment_id
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;
GO

/* ============================================================
   8. ORPHAN CUSTOMER CHECK
   ============================================================ */
SELECT COUNT(DISTINCT o.customer_id) AS OrphanCustomerCount
FROM dbo.stg_orders AS o
LEFT JOIN dbo.stg_customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
GO

/* ============================================================
   9. ORPHAN ORDER CHECK
   ============================================================ */
SELECT COUNT(DISTINCT p.order_id) AS OrphanOrderCount
FROM dbo.stg_payments AS p
LEFT JOIN dbo.stg_orders AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
GO

/* ============================================================
   10. ORDER DATE RANGE
   ============================================================ */
SELECT MIN(order_date) AS MinOrderDate, MAX(order_date) AS MaxOrderDate
FROM dbo.stg_orders;
GO

/* ============================================================
   11. PAYMENT DATE RANGE
   ============================================================ */
SELECT MIN(payment_date) AS MinPaymentDate, MAX(payment_date) AS MaxPaymentDate
FROM dbo.stg_payments;
GO

/* ============================================================
   12. INVALID ORDER DATE CHECK
   ============================================================ */
SELECT COUNT(*) AS FutureDatedOrders
FROM dbo.stg_orders
WHERE order_date > CAST(GETDATE() AS DATE);
GO

/* ============================================================
   13. ORDER STATUS DISTRIBUTION
   ============================================================ */
SELECT
    LOWER(LTRIM(RTRIM(order_status))) AS OrderStatus,
    COUNT(DISTINCT order_id) AS Orders
FROM dbo.stg_orders
GROUP BY LOWER(LTRIM(RTRIM(order_status)))
ORDER BY Orders DESC;
GO

/* ============================================================
   14. PAYMENT STATUS DISTRIBUTION
   ============================================================ */
SELECT
    LOWER(LTRIM(RTRIM(payment_status))) AS PaymentStatus,
    COUNT(DISTINCT payment_id) AS Payments
FROM dbo.stg_payments
GROUP BY LOWER(LTRIM(RTRIM(payment_status)))
ORDER BY Payments DESC;
GO

/* ============================================================
   15. NEGATIVE / INVALID ORDER AMOUNTS
   ============================================================ */
SELECT COUNT(*) AS InvalidOrderAmountRows
FROM dbo.stg_orders
WHERE revenue < 0;
GO

/* ============================================================
   16. NEGATIVE / INVALID PAYMENT AMOUNTS
   ============================================================ */
SELECT COUNT(*) AS InvalidPaymentAmountRows
FROM dbo.stg_payments
WHERE amount < 0;
GO

/* ============================================================
   17. TOTAL ORDER KPI
   ============================================================ */
SELECT COUNT(DISTINCT order_id) AS TotalOrders
FROM dbo.stg_orders;
GO

/* ============================================================
   18. CANCELLED ORDER KPI
   ============================================================ */
SELECT COUNT(DISTINCT order_id) AS CancelledOrders
FROM dbo.stg_orders
WHERE LOWER(LTRIM(RTRIM(order_status))) = 'cancelled';
GO

/* ============================================================
   19. CANCELLATION RATE
   ============================================================ */
SELECT
    COUNT(DISTINCT CASE WHEN LOWER(LTRIM(RTRIM(order_status))) = 'cancelled' THEN order_id END) AS CancelledOrders,
    COUNT(DISTINCT order_id) AS TotalOrders,
    CAST(
        COUNT(DISTINCT CASE WHEN LOWER(LTRIM(RTRIM(order_status))) = 'cancelled' THEN order_id END) * 100.0
        / NULLIF(COUNT(DISTINCT order_id), 0)
        AS DECIMAL(10,2)
    ) AS CancellationRate
FROM dbo.stg_orders;
GO

/* ============================================================
   20. APPROVED KPI RECONCILIATION
   ============================================================ */
WITH OrderMetrics AS
(
    SELECT
        COUNT(DISTINCT order_id) AS TotalOrders,
        COUNT(DISTINCT CASE WHEN LOWER(LTRIM(RTRIM(order_status))) = 'cancelled' THEN order_id END) AS CancelledOrders
    FROM dbo.stg_orders
)
SELECT
    TotalOrders,
    CancelledOrders,
    CAST(CancelledOrders * 100.0 / NULLIF(TotalOrders, 0) AS DECIMAL(10,2)) AS CancellationRate,
    CASE WHEN TotalOrders = 40000 THEN 'PASS' ELSE 'CHECK' END AS TotalOrdersValidation,
    CASE WHEN CancelledOrders = 13381 THEN 'PASS' ELSE 'CHECK' END AS CancelledOrdersValidation,
    CASE
        WHEN ABS((CancelledOrders * 100.0 / NULLIF(TotalOrders, 0)) - 33.45) < 0.01
        THEN 'PASS' ELSE 'CHECK'
    END AS CancellationRateValidation
FROM OrderMetrics;
GO

/* ============================================================
   21. CUSTOMER ORDER COVERAGE
   ============================================================ */
SELECT COUNT(DISTINCT customer_id) AS CustomersWithOrders
FROM dbo.stg_orders
WHERE customer_id IS NOT NULL;
GO

/* ============================================================
   22. CUSTOMER ACTIVITY — LAST ORDER DATE
   ============================================================ */
SELECT
    customer_id,
    MAX(order_date) AS LastOrderDate,
    COUNT(DISTINCT order_id) AS OrderCount
FROM dbo.stg_orders
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY LastOrderDate;
GO

/* ============================================================
   23. 90-DAY CHURN VALIDATION

   90-day inactivity defines CHURN.
   It does NOT automatically define the 2,389 At-Risk Customers.
   At-Risk classification is handled separately using multiple
   behavioural signals.
   ============================================================ */
WITH CustomerActivity AS
(
    SELECT customer_id, MAX(order_date) AS LastOrderDate
    FROM dbo.stg_orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
AnalysisDate AS
(
    SELECT MAX(order_date) AS AnalysisDate
    FROM dbo.stg_orders
)
SELECT
    COUNT(*) AS CustomersWithOrders,
    SUM(
        CASE
            WHEN DATEDIFF(DAY, LastOrderDate, AnalysisDate) >= 90 THEN 1
            ELSE 0
        END
    ) AS CustomersMeeting90DayChurnRule
FROM CustomerActivity
CROSS JOIN AnalysisDate;
GO

/* ============================================================
   24. FINAL DATA QUALITY SUMMARY
   ============================================================ */
SELECT 'Customers' AS Dataset, COUNT(*) AS RowCount
FROM dbo.stg_customers
UNION ALL
SELECT 'Orders', COUNT(*)
FROM dbo.stg_orders
UNION ALL
SELECT 'Payments', COUNT(*)
FROM dbo.stg_payments;
GO

/*
    ============================================================
    VALIDATION NOTES
    ============================================================

    Approved project targets:

    Total Orders          = 40,000
    Cancelled Orders      = 13,381
    Cancellation Rate     = 33.45%
    Revenue Loss          = 2.5M
    At-Risk Customers     = 2,389
    Churn Rule            = 90 days inactivity

    Revenue Loss is NOT hard-coded in this validation script.
    It must be calculated from the revenue-loss business rule.

    At-Risk Customers are NOT defined as 90-day churn customers.
    At-Risk logic combines:
        1. Customer inactivity
        2. Cancellation behaviour
        3. Payment failures
        4. Purchase behaviour

    No Project 1 metrics are used in this project.
    ============================================================
*/