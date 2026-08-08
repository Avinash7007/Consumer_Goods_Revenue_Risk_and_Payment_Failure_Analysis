/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        09_final_validation.sql

    Purpose:
        Final production QA and KPI reconciliation.

    Approved Project Metrics:
        Total Orders          = 40,000
        Cancelled Orders      = 13,381
        Cancellation Rate     = 33.45%
        Revenue Loss          = ₹2.5M
        At-Risk Customers     = 2,389
        Churn Rule            = 90 Days Inactivity

    Technology:
        SQL Server / T-SQL

    IMPORTANT:
        This script is READ-ONLY.
        It does not modify source or staging tables.

        If a KPI returns CHECK, investigate the underlying
        business logic/data instead of manually changing
        the result to match the expected number.
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. DATASET ROW COUNT CHECK
   ============================================================ */

SELECT
    'stg_customers' AS Dataset,
    COUNT(*) AS RowCount
FROM dbo.stg_customers

UNION ALL

SELECT
    'stg_orders',
    COUNT(*)
FROM dbo.stg_orders

UNION ALL

SELECT
    'stg_payments',
    COUNT(*)
FROM dbo.stg_payments;
GO


/* ============================================================
   2. TOTAL ORDERS VALIDATION
   ============================================================ */

WITH Metrics AS
(
    SELECT
        COUNT(DISTINCT order_id) AS TotalOrders
    FROM dbo.stg_orders
)

SELECT

    TotalOrders,

    40000 AS ExpectedTotalOrders,

    TotalOrders - 40000 AS Difference,

    CASE
        WHEN TotalOrders = 40000
            THEN 'PASS'
        ELSE
            'CHECK'
    END AS ValidationStatus

FROM Metrics;
GO


/* ============================================================
   3. CANCELLED ORDERS VALIDATION
   ============================================================ */

WITH Metrics AS
(
    SELECT

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
        ) AS CancelledOrders

    FROM dbo.stg_orders
)

SELECT

    CancelledOrders,

    13381 AS ExpectedCancelledOrders,

    CancelledOrders - 13381 AS Difference,

    CASE
        WHEN CancelledOrders = 13381
            THEN 'PASS'
        ELSE
            'CHECK'
    END AS ValidationStatus

FROM Metrics;
GO


/* ============================================================
   4. CANCELLATION RATE VALIDATION
   ============================================================ */

WITH Metrics AS
(
    SELECT

        COUNT(DISTINCT order_id) AS TotalOrders,

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
        ) AS CancelledOrders

    FROM dbo.stg_orders
)

SELECT

    TotalOrders,

    CancelledOrders,

    CAST(
        CancelledOrders * 100.0
        /
        NULLIF(
            TotalOrders,
            0
        )
        AS DECIMAL(10,2)
    ) AS CalculatedCancellationRate,

    CAST(
        33.45
        AS DECIMAL(10,2)
    ) AS ExpectedCancellationRate,

    CASE

        WHEN ABS(
            (
                CancelledOrders * 100.0
                /
                NULLIF(
                    TotalOrders,
                    0
                )
            ) - 33.45
        ) < 0.01

            THEN 'PASS'

        ELSE
            'CHECK'

    END AS ValidationStatus

FROM Metrics;
GO


/* ============================================================
   5. ORDER ID DUPLICATE CHECK
   ============================================================ */

SELECT

    COUNT(*) AS DuplicateOrderIDGroups

FROM
(
    SELECT
        order_id

    FROM dbo.stg_orders

    GROUP BY
        order_id

    HAVING
        COUNT(*) > 1

) AS DuplicateOrders;
GO


/* ============================================================
   6. CUSTOMER ID DUPLICATE CHECK
   ============================================================ */

SELECT

    COUNT(*) AS DuplicateCustomerIDGroups

FROM
(
    SELECT
        customer_id

    FROM dbo.stg_customers

    GROUP BY
        customer_id

    HAVING
        COUNT(*) > 1

) AS DuplicateCustomers;
GO


/* ============================================================
   7. PAYMENT ID DUPLICATE CHECK
   ============================================================ */

SELECT

    COUNT(*) AS DuplicatePaymentIDGroups

FROM
(
    SELECT
        payment_id

    FROM dbo.stg_payments

    GROUP BY
        payment_id

    HAVING
        COUNT(*) > 1

) AS DuplicatePayments;
GO


/* ============================================================
   8. ORPHAN ORDER → CUSTOMER CHECK
   ============================================================ */

SELECT

    COUNT(*) AS OrphanOrderCustomers

FROM dbo.stg_orders AS o

LEFT JOIN dbo.stg_customers AS c
    ON o.customer_id = c.customer_id

WHERE
    o.customer_id IS NOT NULL

    AND c.customer_id IS NULL;
GO


/* ============================================================
   9. ORPHAN PAYMENT → ORDER CHECK
   ============================================================ */

SELECT

    COUNT(*) AS OrphanPaymentOrders

FROM dbo.stg_payments AS p

LEFT JOIN dbo.stg_orders AS o
    ON p.order_id = o.order_id

WHERE
    p.order_id IS NOT NULL

    AND o.order_id IS NULL;
GO


/* ============================================================
   10. NULL / REQUIRED FIELD CHECK
   ============================================================ */

SELECT

    'Orders - Order ID' AS ValidationItem,

    COUNT(*) AS InvalidRows

FROM dbo.stg_orders

WHERE order_id IS NULL

UNION ALL

SELECT

    'Orders - Customer ID',

    COUNT(*)

FROM dbo.stg_orders

WHERE customer_id IS NULL

UNION ALL

SELECT

    'Orders - Order Date',

    COUNT(*)

FROM dbo.stg_orders

WHERE order_date IS NULL

UNION ALL

SELECT

    'Payments - Payment ID',

    COUNT(*)

FROM dbo.stg_payments

WHERE payment_id IS NULL

UNION ALL

SELECT

    'Payments - Order ID',

    COUNT(*)

FROM dbo.stg_payments

WHERE order_id IS NULL;
GO


/* ============================================================
   11. NEGATIVE REVENUE CHECK
   ============================================================ */

SELECT

    COUNT(*) AS NegativeRevenueRows

FROM dbo.stg_orders

WHERE revenue < 0;
GO


/* ============================================================
   12. NEGATIVE PAYMENT AMOUNT CHECK
   ============================================================ */

SELECT

    COUNT(*) AS NegativePaymentAmountRows

FROM dbo.stg_payments

WHERE amount < 0;
GO


/* ============================================================
   13. FUTURE ORDER DATE CHECK
   ============================================================ */

SELECT

    COUNT(*) AS FutureOrderDates

FROM dbo.stg_orders

WHERE
    order_date > CAST(
        GETDATE()
        AS DATE
    );
GO


/* ============================================================
   14. REVENUE LOSS CALCULATION
   ============================================================ */

WITH RevenueMetrics AS
(
    SELECT

        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(order_status)
                    )
                ) = 'cancelled'

                THEN COALESCE(
                    revenue,
                    0
                )

                ELSE 0

            END
        ) AS CalculatedRevenueLoss

    FROM dbo.stg_orders
)

SELECT

    CAST(
        CalculatedRevenueLoss
        AS DECIMAL(18,2)
    ) AS CalculatedRevenueLoss,

    CAST(
        2500000
        AS DECIMAL(18,2)
    ) AS ExpectedRevenueLoss,

    CAST(
        CalculatedRevenueLoss - 2500000
        AS DECIMAL(18,2)
    ) AS Difference,

    CASE

        WHEN ABS(
            CalculatedRevenueLoss - 2500000
        ) < 1

            THEN 'PASS'

        ELSE
            'CHECK BUSINESS RULE'

    END AS ValidationStatus

FROM RevenueMetrics;
GO


/* ============================================================
   15. 90-DAY CHURN VALIDATION
   ============================================================ */

WITH CustomerActivity AS
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

    COUNT(*) AS TotalCustomers,

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
    ) AS ChurnedCustomers90Days,

    '90 Days Inactivity' AS ApprovedChurnRule

FROM CustomerActivity

CROSS JOIN AnalysisDate;
GO


/* ============================================================
   16. 30-DAY VS 90-DAY CHURN CHECK
   ============================================================ */

WITH CustomerActivity AS
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

    SUM(
        CASE

            WHEN DATEDIFF(
                DAY,
                LastOrderDate,
                AnalysisDate
            ) >= 30

                THEN 1

            ELSE 0

        END
    ) AS Churn30Days,

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
    ) AS Churn90Days,

    '90 Days' AS OfficialChurnDefinition

FROM CustomerActivity

CROSS JOIN AnalysisDate;
GO


/* ============================================================
   17. FINAL AT-RISK CUSTOMER CALCULATION
   ============================================================

   Risk scoring:

       Inactivity:
           90+ days = 2
           60-89 days = 1

       Cancellation:
           2+ = 2
           1  = 1

       Payment:
           2+ = 2
           1  = 1

       Purchase:
           One-time = 1

       High Risk:
           Score >= 5

   NOTE:
       This reproduces the exact scoring model used in
       07_customer_risk_segmentation.sql.
   ============================================================ */

WITH CustomerBase AS
(
    SELECT

        customer_id,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

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
        ) AS CancelledOrders

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

CustomerPayment AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(p.payment_status)
                    )
                ) = 'failed'

                THEN p.payment_id

            END
        ) AS FailedPayments

    FROM dbo.stg_orders AS o

    INNER JOIN dbo.stg_payments AS p
        ON o.order_id = p.order_id

    WHERE
        o.customer_id IS NOT NULL

    GROUP BY
        o.customer_id
),

RiskScore AS
(
    SELECT

        c.customer_id,

        (
            CASE

                WHEN DATEDIFF(
                    DAY,
                    c.LastOrderDate,
                    a.AnalysisDate
                ) >= 90
                    THEN 2

                WHEN DATEDIFF(
                    DAY,
                    c.LastOrderDate,
                    a.AnalysisDate
                ) BETWEEN 60 AND 89
                    THEN 1

                ELSE 0

            END

            +

            CASE

                WHEN c.CancelledOrders >= 2
                    THEN 2

                WHEN c.CancelledOrders = 1
                    THEN 1

                ELSE 0

            END

            +

            CASE

                WHEN COALESCE(
                    p.FailedPayments,
                    0
                ) >= 2
                    THEN 2

                WHEN COALESCE(
                    p.FailedPayments,
                    0
                ) = 1
                    THEN 1

                ELSE 0

            END

            +

            CASE

                WHEN c.TotalOrders = 1
                    THEN 1

                ELSE 0

            END

        ) AS CustomerRiskScore

    FROM CustomerBase AS c

    CROSS JOIN AnalysisDate AS a

    LEFT JOIN CustomerPayment AS p
        ON c.customer_id = p.customer_id
)

SELECT

    COUNT(*) AS CalculatedAtRiskCustomers,

    2389 AS ExpectedAtRiskCustomers,

    COUNT(*) - 2389 AS Difference,

    CASE

        WHEN COUNT(*) = 2389

            THEN 'PASS'

        ELSE
            'CHECK RISK MODEL'

    END AS ValidationStatus

FROM RiskScore

WHERE
    CustomerRiskScore >= 5;
GO


/* ============================================================
   18. FINAL KPI RECONCILIATION TABLE
   ============================================================ */

WITH OrderMetrics AS
(
    SELECT

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

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
        ) AS CancelledOrders,

        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(order_status)
                    )
                ) = 'cancelled'

                THEN COALESCE(
                    revenue,
                    0
                )

                ELSE 0

            END
        ) AS RevenueLoss

    FROM dbo.stg_orders
),

CustomerActivity AS
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

CustomerPayment AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(p.payment_status)
                    )
                ) = 'failed'

                THEN p.payment_id

            END
        ) AS FailedPayments

    FROM dbo.stg_orders AS o

    INNER JOIN dbo.stg_payments AS p
        ON o.order_id = p.order_id

    WHERE o.customer_id IS NOT NULL

    GROUP BY
        o.customer_id
),

CustomerRiskBase AS
(
    SELECT

        c.customer_id,

        c.LastOrderDate,

        DATEDIFF(
            DAY,
            c.LastOrderDate,
            a.AnalysisDate
        ) AS DaysInactive,

        COUNT(
            DISTINCT o.order_id
        ) AS TotalOrders,

        COUNT(
            DISTINCT
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(o.order_status)
                    )
                ) = 'cancelled'

                THEN o.order_id

            END
        ) AS CancelledOrders,

        COALESCE(
            p.FailedPayments,
            0
        ) AS FailedPayments

    FROM CustomerActivity AS c

    CROSS JOIN AnalysisDate AS a

    INNER JOIN dbo.stg_orders AS o
        ON c.customer_id = o.customer_id

    LEFT JOIN CustomerPayment AS p
        ON c.customer_id = p.customer_id

    GROUP BY

        c.customer_id,

        c.LastOrderDate,

        a.AnalysisDate,

        p.FailedPayments
),

RiskScore AS
(
    SELECT

        customer_id,

        (
            CASE

                WHEN DaysInactive >= 90
                    THEN 2

                WHEN DaysInactive BETWEEN 60 AND 89
                    THEN 1

                ELSE 0

            END

            +

            CASE

                WHEN CancelledOrders >= 2
                    THEN 2

                WHEN CancelledOrders = 1
                    THEN 1

                ELSE 0

            END

            +

            CASE

                WHEN FailedPayments >= 2
                    THEN 2

                WHEN FailedPayments = 1
                    THEN 1

                ELSE 0

            END

            +

            CASE

                WHEN TotalOrders = 1
                    THEN 1

                ELSE 0

            END

        ) AS CustomerRiskScore

    FROM CustomerRiskBase
),

RiskMetrics AS
(
    SELECT

        COUNT(*) AS AtRiskCustomers

    FROM RiskScore

    WHERE CustomerRiskScore >= 5
)

SELECT

    'Total Orders' AS KPI,

    CAST(
        om.TotalOrders
        AS VARCHAR(50)
    ) AS CalculatedValue,

    '40,000' AS ExpectedValue,

    CASE

        WHEN om.TotalOrders = 40000
            THEN 'PASS'

        ELSE
            'CHECK'

    END AS ValidationStatus

FROM OrderMetrics AS om

UNION ALL

SELECT

    'Cancelled Orders',

    CAST(
        om.CancelledOrders
        AS VARCHAR(50)
    ),

    '13,381',

    CASE

        WHEN om.CancelledOrders = 13381
            THEN 'PASS'

        ELSE
            'CHECK'

    END

FROM OrderMetrics AS om

UNION ALL

SELECT

    'Cancellation Rate',

    CAST(
        CAST(
            om.CancelledOrders * 100.0
            /
            NULLIF(
                om.TotalOrders,
                0
            )
            AS DECIMAL(10,2)
        )
        AS VARCHAR(50)
    ) + '%',

    '33.45%',

    CASE

        WHEN ABS(
            (
                om.CancelledOrders * 100.0
                /
                NULLIF(
                    om.TotalOrders,
                    0
                )
            ) - 33.45
        ) < 0.01

            THEN 'PASS'

        ELSE
            'CHECK'

    END

FROM OrderMetrics AS om

UNION ALL

SELECT

    'Revenue Loss',

    CAST(
        CAST(
            om.RevenueLoss
            AS DECIMAL(18,2)
        )
        AS VARCHAR(50)
    ),

    '2,500,000',

    CASE

        WHEN ABS(
            om.RevenueLoss - 2500000
        ) < 1

            THEN 'PASS'

        ELSE
            'CHECK'

    END

FROM OrderMetrics AS om

UNION ALL

SELECT

    'At-Risk Customers',

    CAST(
        rm.AtRiskCustomers
        AS VARCHAR(50)
    ),

    '2,389',

    CASE

        WHEN rm.AtRiskCustomers = 2389
            THEN 'PASS'

        ELSE
            'CHECK'

    END

FROM RiskMetrics AS rm;
GO


/* ============================================================
   19. FINAL DATA QUALITY GATE
   ============================================================ */

WITH QualityChecks AS
(
    SELECT

        CASE

            WHEN COUNT(*) = 0
                THEN 1

            ELSE 0

        END AS OrdersWithNullID

    FROM dbo.stg_orders

    WHERE order_id IS NULL

    UNION ALL

    SELECT

        CASE

            WHEN COUNT(*) = 0
                THEN 1

            ELSE 0

        END

    FROM dbo.stg_orders

    WHERE customer_id IS NULL

    UNION ALL

    SELECT

        CASE

            WHEN COUNT(*) = 0
                THEN 1

            ELSE 0

        END

    FROM dbo.stg_payments

    WHERE payment_id IS NULL

    UNION ALL

    SELECT

        CASE

            WHEN COUNT(*) = 0
                THEN 1

            ELSE 0

        END

    FROM dbo.stg_payments

    WHERE order_id IS NULL
)

SELECT

    CASE

        WHEN MIN(
            QualityCheck
        ) = 1

            THEN 'PASS - DATA QUALITY GATE PASSED'

        ELSE
            'FAIL - DATA QUALITY ISSUE FOUND'

    END AS FinalDataQualityStatus

FROM QualityChecks;
GO


/* ============================================================
   20. FINAL PROJECT STATUS
   ============================================================ */

SELECT

    'Customer Churn & Revenue Risk Analysis' AS Project,

    'SQL Server / T-SQL + Python / Pandas'
        AS TechnologyStack,

    '40,000 Orders'
        AS OrderVolume,

    '13,381 Cancelled Orders'
        AS CancellationVolume,

    '33.45% Cancellation Rate'
        AS CancellationRate,

    '₹2.5M Revenue Loss'
        AS RevenueLoss,

    '2,389 At-Risk Customers'
        AS AtRiskCustomers,

    '90 Days Inactivity'
        AS ChurnRule,

    'FINAL QA / RECONCILIATION'
        AS ProjectStatus;
GO


/*
    ============================================================
    FINAL BUSINESS STORY
    ============================================================

    The analysis started with 40,000 customer orders.

    The order analysis identified:

        13,381 cancelled orders
        33.45% cancellation rate

    The revenue-risk analysis quantified:

        ₹2.5M revenue loss

    Customer behaviour analysis evaluated:

        - Purchase frequency
        - Repeat behaviour
        - Last order date
        - Days inactive
        - Purchase gaps

    Payment-risk analysis evaluated:

        - Failed payments
        - Payment failure frequency
        - Customer payment risk

    Churn was defined as:

        90 days of inactivity

    Customer risk segmentation combined:

        Inactivity
            +
        Cancellation behaviour
            +
        Payment failures
            +
        Purchase behaviour

        ↓

        2,389 At-Risk Customers

    FINAL APPROVED PROJECT METRICS:

        Total Orders          = 40,000
        Cancelled Orders      = 13,381
        Cancellation Rate     = 33.45%
        Revenue Loss          = ₹2.5M
        At-Risk Customers     = 2,389
        Churn Rule            = 90 days inactivity

    ============================================================
*/