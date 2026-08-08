/*
Project 2 - Customer Churn & Revenue Risk Analysis
05 - Payment Risk Analysis
SQL Server / T-SQL

Purpose:
    Identify payment-failure signals that will later be combined
    with inactivity, cancellation behaviour and purchase behaviour.

Important:
    Payment failures alone do NOT define the 2,389 at-risk customers.
*/

USE YOUR_DATABASE_NAME;
GO

/* 1. Payment status distribution */
WITH PaymentCounts AS
(
    SELECT
        LOWER(LTRIM(RTRIM(payment_status))) AS PaymentStatus,
        COUNT(DISTINCT payment_id) AS PaymentCount
    FROM dbo.stg_payments
    GROUP BY LOWER(LTRIM(RTRIM(payment_status)))
),
PaymentTotal AS
(
    SELECT SUM(PaymentCount) AS TotalPayments
    FROM PaymentCounts
)
SELECT
    pc.PaymentStatus,
    pc.PaymentCount,
    CAST(
        pc.PaymentCount * 100.0 / NULLIF(pt.TotalPayments, 0)
        AS DECIMAL(10,2)
    ) AS PaymentPercentage
FROM PaymentCounts pc
CROSS JOIN PaymentTotal pt
ORDER BY pc.PaymentCount DESC;
GO

/* 2. Overall payment KPIs */
SELECT
    COUNT(DISTINCT payment_id) AS TotalPayments,
    COUNT(DISTINCT CASE
        WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
        THEN payment_id END) AS FailedPayments,
    CAST(
        COUNT(DISTINCT CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
            THEN payment_id END) * 100.0
        / NULLIF(COUNT(DISTINCT payment_id), 0)
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate,
    CAST(
        SUM(CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
            THEN COALESCE(amount, 0) ELSE 0 END)
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount
FROM dbo.stg_payments;
GO

/* 3. Monthly payment failure trend */
SELECT
    YEAR(payment_date) AS PaymentYear,
    MONTH(payment_date) AS PaymentMonth,
    COUNT(DISTINCT payment_id) AS TotalPayments,
    COUNT(DISTINCT CASE
        WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
        THEN payment_id END) AS FailedPayments,
    CAST(
        COUNT(DISTINCT CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
            THEN payment_id END) * 100.0
        / NULLIF(COUNT(DISTINCT payment_id), 0)
        AS DECIMAL(10,2)
    ) AS FailureRate
FROM dbo.stg_payments
WHERE payment_date IS NOT NULL
GROUP BY YEAR(payment_date), MONTH(payment_date)
ORDER BY PaymentYear, PaymentMonth;
GO

/* 4. Order-level failed-payment behaviour */
SELECT
    order_id,
    COUNT(DISTINCT payment_id) AS PaymentAttempts,
    COUNT(DISTINCT CASE
        WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
        THEN payment_id END) AS FailedPaymentAttempts,
    CAST(
        SUM(CASE
            WHEN LOWER(LTRIM(RTRIM(payment_status))) = 'failed'
            THEN COALESCE(amount, 0) ELSE 0 END)
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount
FROM dbo.stg_payments
WHERE order_id IS NOT NULL
GROUP BY order_id
ORDER BY FailedPaymentAttempts DESC;
GO

/* 5. Customers with payment failures */
SELECT
    o.customer_id,
    COUNT(DISTINCT p.payment_id) AS TotalPaymentAttempts,
    COUNT(DISTINCT CASE
        WHEN LOWER(LTRIM(RTRIM(p.payment_status))) = 'failed'
        THEN p.payment_id END) AS FailedPayments,
    CAST(
        COUNT(DISTINCT CASE
            WHEN LOWER(LTRIM(RTRIM(p.payment_status))) = 'failed'
            THEN p.payment_id END) * 100.0
        / NULLIF(COUNT(DISTINCT p.payment_id), 0)
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate,
    CAST(
        SUM(CASE
            WHEN LOWER(LTRIM(RTRIM(p.payment_status))) = 'failed'
            THEN COALESCE(p.amount, 0) ELSE 0 END)
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount
FROM dbo.stg_orders o
INNER JOIN dbo.stg_payments p
    ON o.order_id = p.order_id
WHERE o.customer_id IS NOT NULL
GROUP BY o.customer_id
ORDER BY FailedPayments DESC, FailedPaymentAmount DESC;
GO

/* 6. Repeated payment-failure customers */
WITH CustomerPaymentRisk AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT p.payment_id) AS TotalPaymentAttempts,
        COUNT(DISTINCT CASE
            WHEN LOWER(LTRIM(RTRIM(p.payment_status))) = 'failed'
            THEN p.payment_id END) AS FailedPayments
    FROM dbo.stg_orders o
    INNER JOIN dbo.stg_payments p
        ON o.order_id = p.order_id
    WHERE o.customer_id IS NOT NULL
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    TotalPaymentAttempts,
    FailedPayments,
    CAST(
        FailedPayments * 100.0 / NULLIF(TotalPaymentAttempts, 0)
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate,
    CASE
        WHEN FailedPayments >= 3
             AND FailedPayments * 100.0 / NULLIF(TotalPaymentAttempts, 0) >= 50
            THEN 'High Payment Risk'
        WHEN FailedPayments >= 2
            THEN 'Medium Payment Risk'
        WHEN FailedPayments = 1
            THEN 'Payment Risk Signal'
        ELSE 'No Payment Risk Signal'
    END AS PaymentRiskSignal
FROM CustomerPaymentRisk
ORDER BY FailedPayments DESC, PaymentFailureRate DESC;
GO

/* 7. Combined cancellation + payment-failure signal */
WITH CustomerSignals AS
(
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS TotalOrders,
        COUNT(DISTINCT CASE
            WHEN LOWER(LTRIM(RTRIM(o.order_status))) = 'cancelled'
            THEN o.order_id END) AS CancelledOrders,
        COUNT(DISTINCT CASE
            WHEN LOWER(LTRIM(RTRIM(p.payment_status))) = 'failed'
            THEN p.payment_id END) AS FailedPayments
    FROM dbo.stg_orders o
    LEFT JOIN dbo.stg_payments p
        ON o.order_id = p.order_id
    WHERE o.customer_id IS NOT NULL
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    TotalOrders,
    CancelledOrders,
    FailedPayments,
    CASE
        WHEN CancelledOrders > 0 AND FailedPayments > 0
            THEN 'Cancellation + Payment Risk'
        WHEN CancelledOrders > 0
            THEN 'Cancellation Risk'
        WHEN FailedPayments > 0
            THEN 'Payment Risk'
        ELSE 'No Risk Signal'
    END AS CombinedRiskSignal
FROM CustomerSignals
ORDER BY
    CASE
        WHEN CancelledOrders > 0 AND FailedPayments > 0 THEN 1
        WHEN CancelledOrders > 0 THEN 2
        WHEN FailedPayments > 0 THEN 3
        ELSE 4
    END,
    FailedPayments DESC;
GO

/* 8. Payment analysis QA */
SELECT
    COUNT(DISTINCT payment_id) AS TotalPayments,
    SUM(CASE WHEN payment_id IS NULL THEN 1 ELSE 0 END) AS NullPaymentIDs,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS NullOrderIDs,
    SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END) AS NegativePaymentAmounts
FROM dbo.stg_payments;
GO

/*
Business interpretation:
    Payment failures are treated as one risk signal.
    The final At-Risk population is produced by the dedicated
    customer-risk segmentation module using multiple signals.
*/
