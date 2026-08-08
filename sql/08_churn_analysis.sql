/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        08_churn_analysis.sql

    Purpose:
        Analyze customer churn using inactivity-based rules.

    Churn Definition:
        90 days of inactivity

    Secondary Comparison:
        30 days of inactivity

    Approved Project Outcome:
        At-Risk Customers = 2,389

    Approved Revenue Loss:
        ₹2.5M

    Important:
        Churn and At-Risk are different concepts.

        Churn:
            Customer has been inactive for 90+ days.

        At-Risk:
            Combination of inactivity, cancellations,
            payment failures and purchase behaviour.
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. ANALYSIS DATE
   ============================================================ */

SELECT
    MAX(
        CAST(order_date AS DATE)
    ) AS AnalysisDate

FROM dbo.stg_orders;
GO


/* ============================================================
   2. CUSTOMER LAST ORDER DATE
   ============================================================ */

SELECT

    customer_id,

    MIN(
        CAST(order_date AS DATE)
    ) AS FirstOrderDate,

    MAX(
        CAST(order_date AS DATE)
    ) AS LastOrderDate,

    COUNT(
        DISTINCT order_id
    ) AS TotalOrders

FROM dbo.stg_orders

WHERE customer_id IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    LastOrderDate;
GO


/* ============================================================
   3. CUSTOMER INACTIVITY
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
        ) AS LastOrderDate,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders

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

    c.FirstOrderDate,

    c.LastOrderDate,

    c.TotalOrders,

    a.AnalysisDate,

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) AS DaysInactive

FROM CustomerActivity AS c

CROSS JOIN AnalysisDate AS a

ORDER BY
    DaysInactive DESC;
GO


/* ============================================================
   4. 30-DAY VS 90-DAY CHURN COMPARISON
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
    ) AS Churn90Days

FROM CustomerActivity

CROSS JOIN AnalysisDate;
GO


/* ============================================================
   5. 30-DAY CHURN RATE
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
            ) >= 30

                THEN 1

            ELSE 0

        END
    ) AS ChurnedCustomers,

    CAST(

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
        ) * 100.0

        /

        NULLIF(
            COUNT(*),
            0
        )

        AS DECIMAL(10,2)

    ) AS ChurnRate30Days

FROM CustomerActivity

CROSS JOIN AnalysisDate;
GO


/* ============================================================
   6. 90-DAY CHURN RATE
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
    ) AS ChurnedCustomers,

    CAST(

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
        ) * 100.0

        /

        NULLIF(
            COUNT(*),
            0
        )

        AS DECIMAL(10,2)

    ) AS ChurnRate90Days

FROM CustomerActivity

CROSS JOIN AnalysisDate;
GO


/* ============================================================
   7. CHURN STATUS BY CUSTOMER
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
        ) AS LastOrderDate,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

        SUM(
            COALESCE(
                revenue,
                0
            )
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

    c.customer_id,

    c.FirstOrderDate,

    c.LastOrderDate,

    c.TotalOrders,

    CAST(
        c.TotalRevenue
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

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

            THEN 'Churned'

        ELSE
            'Active'

    END AS ChurnStatus

FROM CustomerActivity AS c

CROSS JOIN AnalysisDate AS a

ORDER BY

    DaysInactive DESC;
GO


/* ============================================================
   8. CHURN SEGMENT DISTRIBUTION
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
),

CustomerChurn AS
(
    SELECT

        customer_id,

        DATEDIFF(
            DAY,
            LastOrderDate,
            AnalysisDate
        ) AS DaysInactive

    FROM CustomerActivity

    CROSS JOIN AnalysisDate
)

SELECT

    CASE

        WHEN DaysInactive < 30
            THEN 'Active - <30 Days'

        WHEN DaysInactive BETWEEN 30 AND 59
            THEN '30-59 Days'

        WHEN DaysInactive BETWEEN 60 AND 89
            THEN '60-89 Days'

        WHEN DaysInactive >= 90
            THEN 'Churned - 90+ Days'

        ELSE
            'Unknown'

    END AS ChurnSegment,

    COUNT(*) AS CustomerCount

FROM CustomerChurn

GROUP BY

    CASE

        WHEN DaysInactive < 30
            THEN 'Active - <30 Days'

        WHEN DaysInactive BETWEEN 30 AND 59
            THEN '30-59 Days'

        WHEN DaysInactive BETWEEN 60 AND 89
            THEN '60-89 Days'

        WHEN DaysInactive >= 90
            THEN 'Churned - 90+ Days'

        ELSE
            'Unknown'

    END

ORDER BY
    CustomerCount DESC;
GO


/* ============================================================
   9. CHURNED CUSTOMERS BY ORDER FREQUENCY
   ============================================================ */

WITH CustomerActivity AS
(
    SELECT

        customer_id,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

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

ChurnedCustomers AS
(
    SELECT

        customer_id,

        TotalOrders,

        DATEDIFF(
            DAY,
            LastOrderDate,
            AnalysisDate
        ) AS DaysInactive

    FROM CustomerActivity

    CROSS JOIN AnalysisDate

    WHERE DATEDIFF(
        DAY,
        LastOrderDate,
        AnalysisDate
    ) >= 90
)

SELECT

    CASE

        WHEN TotalOrders = 1
            THEN 'One-Time'

        WHEN TotalOrders BETWEEN 2 AND 4
            THEN 'Occasional'

        WHEN TotalOrders >= 5
            THEN 'Frequent'

        ELSE
            'Unknown'

    END AS PurchaseFrequency,

    COUNT(*) AS ChurnedCustomers

FROM ChurnedCustomers

GROUP BY

    CASE

        WHEN TotalOrders = 1
            THEN 'One-Time'

        WHEN TotalOrders BETWEEN 2 AND 4
            THEN 'Occasional'

        WHEN TotalOrders >= 5
            THEN 'Frequent'

        ELSE
            'Unknown'

    END

ORDER BY
    ChurnedCustomers DESC;
GO


/* ============================================================
   10. CHURNED CUSTOMER REVENUE EXPOSURE
   ============================================================ */

WITH CustomerActivity AS
(
    SELECT

        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

        SUM(
            COALESCE(
                revenue,
                0
            )
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

    COUNT(*) AS ChurnedCustomers,

    CAST(
        SUM(
            TotalRevenue
        )
        AS DECIMAL(18,2)
    ) AS HistoricalRevenueFromChurnedCustomers

FROM CustomerActivity AS c

CROSS JOIN AnalysisDate AS a

WHERE

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) >= 90;
GO


/* ============================================================
   11. TOP CHURNED CUSTOMERS BY HISTORICAL REVENUE
   ============================================================ */

WITH CustomerActivity AS
(
    SELECT

        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

        COUNT(
            DISTINCT order_id
        ) AS TotalOrders,

        SUM(
            COALESCE(
                revenue,
                0
            )
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

SELECT TOP (20)

    c.customer_id,

    c.TotalOrders,

    c.LastOrderDate,

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) AS DaysInactive,

    CAST(
        c.TotalRevenue
        AS DECIMAL(18,2)
    ) AS HistoricalRevenue

FROM CustomerActivity AS c

CROSS JOIN AnalysisDate AS a

WHERE

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) >= 90

ORDER BY

    c.TotalRevenue DESC;
GO


/* ============================================================
   12. CHURNED CUSTOMERS WITH CANCELLATION SIGNAL
   ============================================================ */

WITH CustomerActivity AS
(
    SELECT

        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

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
)

SELECT

    COUNT(*) AS ChurnedCustomers,

    SUM(
        CASE

            WHEN CancelledOrders > 0
                THEN 1

            ELSE 0

        END
    ) AS ChurnedCustomersWithCancellationHistory,

    SUM(
        CASE

            WHEN CancelledOrders >= 2
                THEN 1

            ELSE 0

        END
    ) AS ChurnedCustomersWithRepeatedCancellations

FROM CustomerActivity AS c

CROSS JOIN AnalysisDate AS a

WHERE

    DATEDIFF(
        DAY,
        c.LastOrderDate,
        a.AnalysisDate
    ) >= 90;
GO


/* ============================================================
   13. CHURNED CUSTOMERS WITH PAYMENT FAILURE
   ============================================================ */

WITH ChurnedCustomers AS
(
    SELECT

        customer_id

    FROM
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
    ) AS c

    CROSS JOIN
    (
        SELECT

            MAX(
                CAST(order_date AS DATE)
            ) AS AnalysisDate

        FROM dbo.stg_orders

    ) AS a

    WHERE

        DATEDIFF(
            DAY,
            c.LastOrderDate,
            a.AnalysisDate
        ) >= 90
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

    GROUP BY
        o.customer_id
)

SELECT

    COUNT(*) AS ChurnedCustomers,

    SUM(
        CASE

            WHEN COALESCE(
                p.FailedPayments,
                0
            ) > 0

                THEN 1

            ELSE 0

        END
    ) AS ChurnedCustomersWithPaymentFailure,

    SUM(
        CASE

            WHEN COALESCE(
                p.FailedPayments,
                0
            ) >= 2

                THEN 1

            ELSE 0

        END
    ) AS ChurnedCustomersWithRepeatedPaymentFailure

FROM ChurnedCustomers AS c

LEFT JOIN CustomerPayment AS p
    ON c.customer_id = p.customer_id;
GO


/* ============================================================
   14. CHURN REACTIVATION OPPORTUNITY
   ============================================================

   Customers inactive for 30-89 days are not yet classified
   as churned under the project definition.

   They represent a potential reactivation opportunity.
   ============================================================ */

WITH CustomerActivity AS
(
    SELECT

        customer_id,

        MAX(
            CAST(order_date AS DATE)
        ) AS LastOrderDate,

        SUM(
            COALESCE(
                revenue,
                0
            )
        ) AS HistoricalRevenue

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

    CASE

        WHEN DATEDIFF(
            DAY,
            LastOrderDate,
            AnalysisDate
        ) BETWEEN 30 AND 59

            THEN '30-59 Days'

        WHEN DATEDIFF(
            DAY,
            LastOrderDate,
            AnalysisDate
        ) BETWEEN 60 AND 89

            THEN '60-89 Days'

    END AS ReactivationSegment,

    COUNT(*) AS Customers,

    CAST(
        SUM(
            HistoricalRevenue
        )
        AS DECIMAL(18,2)
    ) AS HistoricalRevenue

FROM CustomerActivity

CROSS JOIN AnalysisDate

WHERE

    DATEDIFF(
        DAY,
        LastOrderDate,
        AnalysisDate
    ) BETWEEN 30 AND 89

GROUP BY

    CASE

        WHEN DATEDIFF(
            DAY,
            LastOrderDate,
            AnalysisDate
        ) BETWEEN 30 AND 59

            THEN '30-59 Days'

        WHEN DATEDIFF(
            DAY,
            LastOrderDate,
            AnalysisDate
        ) BETWEEN 60 AND 89

            THEN '60-89 Days'

    END

ORDER BY
    ReactivationSegment;
GO


/* ============================================================
   15. 30-DAY VS 90-DAY STAKEHOLDER COMPARISON
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
),

Comparison AS
(
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

        COUNT(*) AS TotalCustomers

    FROM CustomerActivity

    CROSS JOIN AnalysisDate
)

SELECT

    TotalCustomers,

    Churn30Days,

    Churn90Days,

    CAST(
        Churn30Days * 100.0
        /
        NULLIF(
            TotalCustomers,
            0
        )
        AS DECIMAL(10,2)
    ) AS ChurnRate30Days,

    CAST(
        Churn90Days * 100.0
        /
        NULLIF(
            TotalCustomers,
            0
        )
        AS DECIMAL(10,2)
    ) AS ChurnRate90Days,

    Churn30Days - Churn90Days
        AS AdditionalCustomersFlaggedBy30DayRule

FROM Comparison;
GO


/* ============================================================
   16. FINAL CHURN SUMMARY
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
            ) < 30

                THEN 1

            ELSE 0

        END
    ) AS ActiveCustomers,

    SUM(
        CASE

            WHEN DATEDIFF(
                DAY,
                LastOrderDate,
                AnalysisDate
            ) BETWEEN 30 AND 89

                THEN 1

            ELSE 0

        END
    ) AS AtRiskInactivityWindow,

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
    ) AS ChurnedCustomers90Days

FROM CustomerActivity

CROSS JOIN AnalysisDate;
GO


/*
    ============================================================
    BUSINESS INTERPRETATION
    ============================================================

    Churn definition:

        90 consecutive days of inactivity based on the
        customer's last recorded order.

    Why 90 days?

        A shorter 30-day rule can classify customers with
        naturally longer purchase cycles as churned.

        Therefore 30 days is shown as a comparison,
        while 90 days remains the project's official
        churn definition.

    Customer lifecycle:

        <30 days
            ↓
        Active

        30-59 days
            ↓
        Early Reactivation Opportunity

        60-89 days
            ↓
        High Inactivity / Reactivation Risk

        90+ days
            ↓
        Churned

    IMPORTANT:

        Churned ≠ At-Risk.

    Churn is defined only by 90-day inactivity.

    At-Risk customers are identified using:

        Inactivity
        +
        Cancellation behaviour
        +
        Payment failures
        +
        Purchase behaviour

    Approved project outcomes:

        At-Risk Customers = 2,389
        Revenue Loss       = ₹2.5M

    These are reconciled in the final validation layer.
    ============================================================
*/