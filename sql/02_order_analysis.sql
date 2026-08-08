/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        02_order_analysis.sql

    Purpose:
        Analyze order-level behaviour before moving into
        cancellation, payment-risk and customer-risk analysis.

    Source:
        dbo.stg_orders

    Technology:
        SQL Server / T-SQL

    Approved Project KPI:
        Total Orders = 40,000
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. TOTAL ORDER VOLUME
   ============================================================ */

SELECT
    COUNT(DISTINCT order_id) AS TotalOrders
FROM dbo.stg_orders;
GO


/* ============================================================
   2. ORDER STATUS DISTRIBUTION
   ============================================================ */

SELECT
    LOWER(
        LTRIM(
            RTRIM(order_status)
        )
    ) AS OrderStatus,

    COUNT(DISTINCT order_id) AS OrderCount,

    CAST(
        COUNT(DISTINCT order_id) * 100.0
        / NULLIF(
            (
                SELECT COUNT(DISTINCT order_id)
                FROM dbo.stg_orders
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS OrderPercentage

FROM dbo.stg_orders

GROUP BY
    LOWER(
        LTRIM(
            RTRIM(order_status)
        )
    )

ORDER BY
    OrderCount DESC;
GO


/* ============================================================
   3. DAILY ORDER VOLUME
   ============================================================ */

SELECT
    CAST(order_date AS DATE) AS OrderDate,

    COUNT(DISTINCT order_id) AS Orders

FROM dbo.stg_orders

WHERE order_date IS NOT NULL

GROUP BY
    CAST(order_date AS DATE)

ORDER BY
    OrderDate;
GO


/* ============================================================
   4. MONTHLY ORDER VOLUME
   ============================================================ */

SELECT
    YEAR(order_date) AS OrderYear,

    MONTH(order_date) AS OrderMonth,

    DATENAME(
        MONTH,
        order_date
    ) AS MonthName,

    COUNT(DISTINCT order_id) AS Orders

FROM dbo.stg_orders

WHERE order_date IS NOT NULL

GROUP BY
    YEAR(order_date),

    MONTH(order_date),

    DATENAME(
        MONTH,
        order_date
    )

ORDER BY
    OrderYear,

    OrderMonth;
GO


/* ============================================================
   5. YEARLY ORDER VOLUME
   ============================================================ */

SELECT
    YEAR(order_date) AS OrderYear,

    COUNT(DISTINCT order_id) AS Orders

FROM dbo.stg_orders

WHERE order_date IS NOT NULL

GROUP BY
    YEAR(order_date)

ORDER BY
    OrderYear;
GO


/* ============================================================
   6. ORDERS BY CUSTOMER
   ============================================================ */

SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS OrderCount

FROM dbo.stg_orders

WHERE customer_id IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    OrderCount DESC;
GO


/* ============================================================
   7. CUSTOMER ORDER FREQUENCY
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS OrderCount

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    OrderCount,

    COUNT(*) AS CustomerCount

FROM CustomerOrders

GROUP BY
    OrderCount

ORDER BY
    OrderCount;
GO


/* ============================================================
   8. ONE-TIME VS REPEAT CUSTOMERS
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS OrderCount

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    CASE
        WHEN OrderCount = 1
            THEN 'One-Time Customer'

        ELSE 'Repeat Customer'

    END AS CustomerType,

    COUNT(*) AS CustomerCount

FROM CustomerOrders

GROUP BY
    CASE
        WHEN OrderCount = 1
            THEN 'One-Time Customer'

        ELSE 'Repeat Customer'

    END

ORDER BY
    CustomerCount DESC;
GO


/* ============================================================
   9. AVERAGE ORDERS PER CUSTOMER
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS OrderCount

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    CAST(
        AVG(
            CAST(
                OrderCount AS DECIMAL(18,2)
            )
        )
        AS DECIMAL(18,2)
    ) AS AverageOrdersPerCustomer

FROM CustomerOrders;
GO


/* ============================================================
   10. FIRST AND LAST ORDER DATE BY CUSTOMER
   ============================================================ */

SELECT
    customer_id,

    MIN(order_date) AS FirstOrderDate,

    MAX(order_date) AS LastOrderDate,

    COUNT(DISTINCT order_id) AS TotalOrders

FROM dbo.stg_orders

WHERE customer_id IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    LastOrderDate DESC;
GO


/* ============================================================
   11. CUSTOMER ORDER LIFESPAN
   ============================================================ */

WITH CustomerActivity AS
(
    SELECT
        customer_id,

        MIN(
            CAST(order_date AS DATE)
        ) AS FirstOrderDate,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    customer_id,

    FirstOrderDate,

    LastOrderDate,

    DATEDIFF(
        DAY,
        FirstOrderDate,
        LastOrderDate
    ) AS CustomerLifespanDays

FROM CustomerActivity

ORDER BY
    CustomerLifespanDays DESC;
GO


/* ============================================================
   12. ORDER VALUE DISTRIBUTION
   ============================================================ */

SELECT
    COUNT(DISTINCT order_id) AS TotalOrders,

    CAST(
        MIN(revenue)
        AS DECIMAL(18,2)
    ) AS MinimumOrderRevenue,

    CAST(
        MAX(revenue)
        AS DECIMAL(18,2)
    ) AS MaximumOrderRevenue,

    CAST(
        AVG(
            CAST(
                revenue AS DECIMAL(18,2)
            )
        )
        AS DECIMAL(18,2)
    ) AS AverageOrderRevenue,

    CAST(
        SUM(revenue)
        AS DECIMAL(18,2)
    ) AS TotalOrderRevenue

FROM dbo.stg_orders

WHERE revenue IS NOT NULL;
GO


/* ============================================================
   13. MONTHLY REVENUE AND ORDER VOLUME
   ============================================================ */

SELECT
    YEAR(order_date) AS OrderYear,

    MONTH(order_date) AS OrderMonth,

    DATENAME(
        MONTH,
        order_date
    ) AS MonthName,

    COUNT(DISTINCT order_id) AS Orders,

    CAST(
        SUM(revenue)
        AS DECIMAL(18,2)
    ) AS Revenue,

    CAST(
        AVG(
            CAST(
                revenue AS DECIMAL(18,2)
            )
        )
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM dbo.stg_orders

WHERE
    order_date IS NOT NULL
    AND revenue IS NOT NULL

GROUP BY
    YEAR(order_date),

    MONTH(order_date),

    DATENAME(
        MONTH,
        order_date
    )

ORDER BY
    OrderYear,

    OrderMonth;
GO


/* ============================================================
   14. CUSTOMER REVENUE CONTRIBUTION
   ============================================================ */

SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS Orders,

    CAST(
        SUM(revenue)
        AS DECIMAL(18,2)
    ) AS TotalRevenue

FROM dbo.stg_orders

WHERE
    customer_id IS NOT NULL
    AND revenue IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    TotalRevenue DESC;
GO


/* ============================================================
   15. TOP 10 CUSTOMERS BY REVENUE
   ============================================================ */

SELECT TOP (10)

    customer_id,

    COUNT(DISTINCT order_id) AS Orders,

    CAST(
        SUM(revenue)
        AS DECIMAL(18,2)
    ) AS TotalRevenue

FROM dbo.stg_orders

WHERE
    customer_id IS NOT NULL
    AND revenue IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    TotalRevenue DESC;
GO


/* ============================================================
   16. CUSTOMER REVENUE RANKING
   ============================================================ */

WITH CustomerRevenue AS
(
    SELECT
        customer_id,

        SUM(revenue) AS TotalRevenue

    FROM dbo.stg_orders

    WHERE
        customer_id IS NOT NULL
        AND revenue IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    customer_id,

    CAST(
        TotalRevenue
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    DENSE_RANK() OVER
    (
        ORDER BY
            TotalRevenue DESC
    ) AS RevenueRank

FROM CustomerRevenue

ORDER BY
    RevenueRank;
GO


/* ============================================================
   17. CUSTOMER PURCHASE SEQUENCE
      LAG() used to compare consecutive orders.
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        order_id,

        CAST(
            order_date AS DATE
        ) AS OrderDate,

        LAG(
            CAST(order_date AS DATE)
        )
        OVER
        (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS PreviousOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL
)

SELECT
    customer_id,

    order_id,

    OrderDate,

    PreviousOrderDate,

    DATEDIFF(
        DAY,
        PreviousOrderDate,
        OrderDate
    ) AS DaysSincePreviousOrder

FROM CustomerOrders

ORDER BY
    customer_id,

    OrderDate;
GO


/* ============================================================
   18. CUSTOMER PURCHASE FREQUENCY SUMMARY
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS OrderCount,

        MIN(
            CAST(order_date AS DATE)
        ) AS FirstOrderDate,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    customer_id,

    OrderCount,

    FirstOrderDate,

    LastOrderDate,

    CASE
        WHEN OrderCount = 1
            THEN 'One-Time'

        WHEN OrderCount BETWEEN 2 AND 4
            THEN 'Occasional'

        WHEN OrderCount >= 5
            THEN 'Frequent'

        ELSE 'Unknown'

    END AS PurchaseFrequencySegment

FROM CustomerOrders

ORDER BY
    OrderCount DESC;
GO


/* ============================================================
   19. TOTAL ORDER RECONCILIATION
   ============================================================ */

SELECT
    COUNT(DISTINCT order_id) AS CalculatedTotalOrders,

    40000 AS ApprovedTotalOrders,

    CASE
        WHEN COUNT(DISTINCT order_id) = 40000
            THEN 'PASS'

        ELSE 'CHECK'

    END AS ValidationStatus

FROM dbo.stg_orders;
GO


/* ============================================================
   20. ORDER ANALYSIS SUMMARY
   ============================================================ */

SELECT

    COUNT(DISTINCT order_id)
        AS TotalOrders,

    COUNT(DISTINCT customer_id)
        AS CustomersWithOrders,

    COUNT(DISTINCT
        CASE
            WHEN LOWER(
                LTRIM(
                    RTRIM(order_status)
                )
            ) = 'cancelled'
            THEN order_id
        END
    )
        AS CancelledOrders,

    CAST(
        COUNT(
            DISTINCT
            CASE
                WHEN LOWER(
                    LTRIM(
                        RTRIM(order_status)
                    )
                ) = 'cancelled'
                THEN order_id
            END
        ) * 100.0
        /
        NULLIF(
            COUNT(DISTINCT order_id),
            0
        )
        AS DECIMAL(10,2)
    )
        AS CancellationRate,

    CAST(
        SUM(revenue)
        AS DECIMAL(18,2)
    )
        AS TotalRevenue

FROM dbo.stg_orders;
GO


/*
    ============================================================
    BUSINESS INTERPRETATION
    ============================================================

    This module establishes the order-level foundation
    for the project.

    Key approved project metrics:

        Total Orders       = 40,000
        Cancelled Orders   = 13,381
        Cancellation Rate  = 33.45%

    This script does NOT calculate the final At-Risk
    customer population.

    At-Risk classification is handled later using:

        - Customer inactivity
        - Cancellation behaviour
        - Payment failures
        - Purchase behaviour

    Churn definition:

        90 days of inactivity

    Revenue Loss:

        ₹2.5M

    Revenue-loss calculation is intentionally handled
    in a dedicated analysis module rather than being
    mixed into the order-volume analysis.
    ============================================================
*/