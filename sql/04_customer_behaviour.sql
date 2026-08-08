/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        04_customer_behaviour.sql

    Purpose:
        Analyze customer purchase behaviour and create the
        behavioural signals required for risk segmentation.

    Source:
        dbo.stg_orders
        dbo.stg_customers

    Technology:
        SQL Server / T-SQL

    Project Definitions:
        Churn = 90 days inactivity
        At-Risk = Combined behavioural risk signals

    Approved Project KPI:
        At-Risk Customers = 2,389

    Important:
        This module does NOT finalize the 2,389 At-Risk count.
        Final risk segmentation is handled separately.
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. CUSTOMER ORDER SUMMARY
   ============================================================ */

SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS TotalOrders,

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

ORDER BY
    TotalOrders DESC;
GO


/* ============================================================
   2. CUSTOMER REVENUE SUMMARY
   ============================================================ */

SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS TotalOrders,

    CAST(
        SUM(
            COALESCE(revenue, 0)
        )
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    CAST(
        AVG(
            COALESCE(revenue, 0)
        )
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM dbo.stg_orders

WHERE customer_id IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    TotalRevenue DESC;
GO


/* ============================================================
   3. FIRST VS REPEAT CUSTOMER
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT

    CASE

        WHEN TotalOrders = 1
            THEN 'New / One-Time Customer'

        WHEN TotalOrders >= 2
            THEN 'Repeat Customer'

        ELSE
            'Unknown'

    END AS CustomerType,

    COUNT(*) AS CustomerCount

FROM CustomerOrders

GROUP BY

    CASE

        WHEN TotalOrders = 1
            THEN 'New / One-Time Customer'

        WHEN TotalOrders >= 2
            THEN 'Repeat Customer'

        ELSE
            'Unknown'

    END

ORDER BY
    CustomerCount DESC;
GO


/* ============================================================
   4. PURCHASE FREQUENCY SEGMENT
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        customer_id,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    customer_id,

    TotalOrders,

    CASE

        WHEN TotalOrders = 1
            THEN 'One-Time'

        WHEN TotalOrders BETWEEN 2 AND 4
            THEN 'Occasional'

        WHEN TotalOrders >= 5
            THEN 'Frequent'

        ELSE
            'Unknown'

    END AS PurchaseFrequencySegment

FROM CustomerOrders

ORDER BY
    TotalOrders DESC;
GO


/* ============================================================
   5. CUSTOMER PURCHASE RANK
   ============================================================ */

WITH CustomerRevenue AS
(
    SELECT
        customer_id,

        SUM(
            COALESCE(revenue, 0)
        ) AS TotalRevenue

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

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
   6. CUSTOMER VALUE SEGMENT
   ============================================================ */

WITH CustomerRevenue AS
(
    SELECT
        customer_id,

        SUM(
            COALESCE(revenue, 0)
        ) AS TotalRevenue

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
),

RevenueDistribution AS
(
    SELECT
        customer_id,

        TotalRevenue,

        NTILE(4) OVER
        (
            ORDER BY
                TotalRevenue
        ) AS RevenueQuartile

    FROM CustomerRevenue
)

SELECT
    customer_id,

    CAST(
        TotalRevenue
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    RevenueQuartile,

    CASE

        WHEN RevenueQuartile = 4
            THEN 'High Value'

        WHEN RevenueQuartile = 3
            THEN 'Medium-High Value'

        WHEN RevenueQuartile = 2
            THEN 'Medium Value'

        WHEN RevenueQuartile = 1
            THEN 'Low Value'

        ELSE
            'Unknown'

    END AS CustomerValueSegment

FROM RevenueDistribution

ORDER BY
    TotalRevenue DESC;
GO


/* ============================================================
   7. ORDER-TO-ORDER PURCHASE GAP
      LAG() compares each order with the customer's
      previous order.
   ============================================================ */

WITH CustomerOrderHistory AS
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
            ORDER BY
                order_date,
                order_id
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
    ) AS DaysBetweenOrders

FROM CustomerOrderHistory

ORDER BY
    customer_id,

    OrderDate;
GO


/* ============================================================
   8. AVERAGE PURCHASE GAP BY CUSTOMER
   ============================================================ */

WITH CustomerOrderHistory AS
(
    SELECT
        customer_id,

        CAST(
            order_date AS DATE
        ) AS OrderDate,

        LAG(
            CAST(order_date AS DATE)
        )
        OVER
        (
            PARTITION BY customer_id
            ORDER BY
                order_date,
                order_id
        ) AS PreviousOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL
),

CustomerGaps AS
(
    SELECT
        customer_id,

        DATEDIFF(
            DAY,
            PreviousOrderDate,
            OrderDate
        ) AS DaysBetweenOrders

    FROM CustomerOrderHistory

    WHERE PreviousOrderDate IS NOT NULL
)

SELECT
    customer_id,

    CAST(
        AVG(
            CAST(
                DaysBetweenOrders AS DECIMAL(18,2)
            )
        )
        AS DECIMAL(18,2)
    ) AS AverageDaysBetweenOrders,

    MAX(
        DaysBetweenOrders
    ) AS MaximumPurchaseGap

FROM CustomerGaps

GROUP BY
    customer_id

ORDER BY
    AverageDaysBetweenOrders DESC;
GO


/* ============================================================
   9. LONG PURCHASE GAP CUSTOMERS
   ============================================================ */

WITH CustomerOrderHistory AS
(
    SELECT
        customer_id,

        CAST(
            order_date AS DATE
        ) AS OrderDate,

        LAG(
            CAST(order_date AS DATE)
        )
        OVER
        (
            PARTITION BY customer_id
            ORDER BY
                order_date,
                order_id
        ) AS PreviousOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL
),

CustomerGaps AS
(
    SELECT
        customer_id,

        DATEDIFF(
            DAY,
            PreviousOrderDate,
            OrderDate
        ) AS DaysBetweenOrders

    FROM CustomerOrderHistory

    WHERE PreviousOrderDate IS NOT NULL
)

SELECT
    customer_id,

    MAX(
        DaysBetweenOrders
    ) AS MaximumPurchaseGap

FROM CustomerGaps

GROUP BY
    customer_id

HAVING
    MAX(
        DaysBetweenOrders
    ) >= 90

ORDER BY
    MaximumPurchaseGap DESC;
GO


/* ============================================================
   10. LAST ORDER DATE
   ============================================================ */

SELECT
    customer_id,

    MAX(
        CAST(order_date AS DATE)
    ) AS LastOrderDate

FROM dbo.stg_orders

WHERE customer_id IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    LastOrderDate;
GO


/* ============================================================
   11. CUSTOMER INACTIVITY
   ============================================================ */

WITH CustomerLastOrder AS
(
    SELECT
        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
),

AnalysisDate AS
(
    SELECT
        MAX(
            CAST(order_date AS DATE)
        ) AS AnalysisDate

    FROM dbo.stg_orders
)

SELECT
    c.customer_id,

    c.LastOrderDate,

    a.AnalysisDate,

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) AS DaysInactive

FROM CustomerLastOrder AS c

CROSS JOIN AnalysisDate AS a

ORDER BY
    DaysInactive DESC;
GO


/* ============================================================
   12. INACTIVITY SEGMENTS
   ============================================================ */

WITH CustomerLastOrder AS
(
    SELECT
        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
),

AnalysisDate AS
(
    SELECT
        MAX(
            CAST(order_date AS DATE)
        ) AS AnalysisDate

    FROM dbo.stg_orders
),

CustomerInactivity AS
(
    SELECT
        c.customer_id,

        DATEDIFF(
            DAY,
            c.LastOrderDate,
            a.AnalysisDate
        ) AS DaysInactive

    FROM CustomerLastOrder AS c

    CROSS JOIN AnalysisDate AS a
)

SELECT
    customer_id,

    DaysInactive,

    CASE

        WHEN DaysInactive < 30
            THEN 'Active'

        WHEN DaysInactive BETWEEN 30 AND 59
            THEN '30-59 Days'

        WHEN DaysInactive BETWEEN 60 AND 89
            THEN '60-89 Days'

        WHEN DaysInactive >= 90
            THEN '90+ Days'

        ELSE
            'Unknown'

    END AS InactivitySegment

FROM CustomerInactivity

ORDER BY
    DaysInactive DESC;
GO


/* ============================================================
   13. 90-DAY CHURN FLAG
   ============================================================ */

WITH CustomerLastOrder AS
(
    SELECT
        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
),

AnalysisDate AS
(
    SELECT
        MAX(
            CAST(order_date AS DATE)
        ) AS AnalysisDate

    FROM dbo.stg_orders
)

SELECT
    c.customer_id,

    c.LastOrderDate,

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) AS DaysInactive,

    CASE

        WHEN DATEDIFF(
            DAY,
            c.LastOrderDate,
            a.AnalysisDate
        ) >= 90
            THEN 1

        ELSE 0

    END AS Churn90DayFlag

FROM CustomerLastOrder AS c

CROSS JOIN AnalysisDate AS a

ORDER BY
    DaysInactive DESC;
GO


/* ============================================================
   14. CUSTOMER BEHAVIOUR MASTER DATASET
   ============================================================

   This query combines the major customer-level behavioural
   signals into one analytical result.

   It is still NOT the final At-Risk segmentation.
   ============================================================ */

WITH CustomerBase AS
(
    SELECT
        customer_id,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

        MIN(
            CAST(order_date AS DATE)
        ) AS FirstOrderDate,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

        SUM(
            COALESCE(revenue, 0)
        ) AS TotalRevenue

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
),

AnalysisDate AS
(
    SELECT
        MAX(
            CAST(order_date AS DATE)
        ) AS AnalysisDate

    FROM dbo.stg_orders
),

CustomerBehaviour AS
(
    SELECT
        c.customer_id,

        c.TotalOrders,

        c.FirstOrderDate,

        c.LastOrderDate,

        c.TotalRevenue,

        a.AnalysisDate,

        DATEDIFF(
            DAY,
            c.LastOrderDate,
            a.AnalysisDate
        ) AS DaysInactive

    FROM CustomerBase AS c

    CROSS JOIN AnalysisDate AS a
)

SELECT
    customer_id,

    TotalOrders,

    FirstOrderDate,

    LastOrderDate,

    AnalysisDate,

    DaysInactive,

    CAST(
        TotalRevenue
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    CASE

        WHEN TotalOrders = 1
            THEN 'One-Time'

        WHEN TotalOrders BETWEEN 2 AND 4
            THEN 'Occasional'

        WHEN TotalOrders >= 5
            THEN 'Frequent'

        ELSE
            'Unknown'

    END AS PurchaseFrequencySegment,

    CASE

        WHEN DaysInactive < 30
            THEN 'Active'

        WHEN DaysInactive BETWEEN 30 AND 59
            THEN '30-59 Days'

        WHEN DaysInactive BETWEEN 60 AND 89
            THEN '60-89 Days'

        WHEN DaysInactive >= 90
            THEN '90+ Days'

        ELSE
            'Unknown'

    END AS InactivitySegment,

    CASE

        WHEN DaysInactive >= 90
            THEN 1

        ELSE 0

    END AS Churn90DayFlag

FROM CustomerBehaviour

ORDER BY
    DaysInactive DESC,

    TotalRevenue DESC;
GO


/* ============================================================
   15. CUSTOMER BEHAVIOUR SUMMARY
   ============================================================ */

WITH CustomerBase AS
(
    SELECT
        customer_id,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

        MIN(
            CAST(order_date AS DATE)
        ) AS FirstOrderDate,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

        SUM(
            COALESCE(revenue, 0)
        ) AS TotalRevenue

    FROM dbo.stg_orders

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
),

AnalysisDate AS
(
    SELECT
        MAX(
            CAST(order_date AS DATE)
        ) AS AnalysisDate

    FROM dbo.stg_orders
)

SELECT

    COUNT(*) AS Customers,

    SUM(
        CASE
            WHEN TotalOrders = 1
                THEN 1
            ELSE 0
        END
    ) AS OneTimeCustomers,

    SUM(
        CASE
            WHEN TotalOrders >= 2
                THEN 1
            ELSE 0
        END
    ) AS RepeatCustomers,

    SUM(
        CASE
            WHEN DATEDIFF(
                DAY,
                LastOrderDate,
                AnalysisDate
            ) >= 90
                THEN 1
            ELSE 0
        END
    ) AS CustomersMeeting90DayChurnRule,

    CAST(
        SUM(
            COALESCE(
                TotalRevenue,
                0
            )
        )
        AS DECIMAL(18,2)
    ) AS TotalCustomerRevenue

FROM CustomerBase

CROSS JOIN AnalysisDate;
GO


/*
    ============================================================
    BUSINESS INTERPRETATION
    ============================================================

    This module establishes the customer behaviour layer.

    Key signals created:

        - Total Orders
        - First Order Date
        - Last Order Date
        - Total Revenue
        - Purchase Frequency
        - Repeat Customer Flag
        - Purchase Gap
        - Average Purchase Gap
        - Maximum Purchase Gap
        - Days Inactive
        - 90-Day Churn Flag

    Churn Definition:

        DaysInactive >= 90

    IMPORTANT:

        90-day churn is only ONE customer-risk signal.

    Final At-Risk logic will combine:

        Customer Inactivity
              +
        Cancellation Behaviour
              +
        Payment Failure
              +
        Purchase Behaviour
              ↓
        Customer Risk Segmentation
              ↓
        Target = 2,389 At-Risk Customers

    The 2,389 value is NOT hard-coded in this module.
    ============================================================
*/