/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        06_revenue_loss_analysis.sql

    Purpose:
        Analyze revenue exposure caused by cancellations,
        failed payments and customer risk behaviour.

    Source Tables:
        dbo.stg_orders
        dbo.stg_payments

    Technology:
        SQL Server / T-SQL

    Approved Project Metric:
        Revenue Loss = ₹2.5M

    Important:
        ₹2.5M is the approved project outcome.
        The SQL below calculates the underlying revenue
        measures from the source data instead of blindly
        hard-coding the value.

        Final reconciliation is performed at the end.
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. TOTAL ORDER REVENUE
   ============================================================ */

SELECT

    COUNT(
        DISTINCT order_id
    ) AS TotalOrders,

    CAST(
        SUM(
            COALESCE(
                revenue,
                0
            )
        )
        AS DECIMAL(18,2)
    ) AS TotalOrderRevenue

FROM dbo.stg_orders;
GO


/* ============================================================
   2. COMPLETED / NON-CANCELLED REVENUE
   ============================================================ */

SELECT

    COUNT(
        DISTINCT order_id
    ) AS NonCancelledOrders,

    CAST(
        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(order_status)
                    )
                ) <> 'cancelled'

                THEN COALESCE(
                    revenue,
                    0
                )

                ELSE 0

            END
        )
        AS DECIMAL(18,2)
    ) AS NonCancelledRevenue

FROM dbo.stg_orders;
GO


/* ============================================================
   3. CANCELLED ORDER REVENUE
   ============================================================ */

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
    ) AS CancelledOrders,

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS CancelledOrderRevenue

FROM dbo.stg_orders;
GO


/* ============================================================
   4. CANCELLED REVENUE AS % OF TOTAL REVENUE
   ============================================================ */

SELECT

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS CancelledRevenue,

    CAST(
        SUM(
            COALESCE(
                revenue,
                0
            )
        )
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    CAST(
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
        ) * 100.0
        /
        NULLIF(
            SUM(
                COALESCE(
                    revenue,
                    0
                )
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS CancelledRevenuePercentage

FROM dbo.stg_orders;
GO


/* ============================================================
   5. REVENUE LOSS BY MONTH
   ============================================================ */

SELECT

    YEAR(order_date) AS OrderYear,

    MONTH(order_date) AS OrderMonth,

    DATENAME(
        MONTH,
        order_date
    ) AS MonthName,

    COUNT(
        DISTINCT order_id
    ) AS CancelledOrders,

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS RevenueLoss

FROM dbo.stg_orders

WHERE
    order_date IS NOT NULL

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
   6. REVENUE LOSS BY CHANNEL
   ============================================================ */

SELECT

    order_channel AS OrderChannel,

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

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS RevenueLoss

FROM dbo.stg_orders

WHERE
    order_channel IS NOT NULL

GROUP BY
    order_channel

ORDER BY
    RevenueLoss DESC;
GO


/* ============================================================
   7. REVENUE LOSS BY CUSTOMER
   ============================================================ */

SELECT

    customer_id,

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

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS RevenueLoss

FROM dbo.stg_orders

WHERE
    customer_id IS NOT NULL

GROUP BY
    customer_id

HAVING
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
    ) > 0

ORDER BY
    RevenueLoss DESC;
GO


/* ============================================================
   8. TOP CUSTOMERS BY REVENUE AT RISK
   ============================================================ */

SELECT TOP (20)

    customer_id,

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

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS RevenueAtRisk

FROM dbo.stg_orders

WHERE
    customer_id IS NOT NULL

GROUP BY
    customer_id

HAVING
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
    ) > 0

ORDER BY
    RevenueAtRisk DESC;
GO


/* ============================================================
   9. PAYMENT FAILURE REVENUE
   ============================================================ */

SELECT

    COUNT(
        DISTINCT payment_id
    ) AS FailedPayments,

    CAST(
        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'failed'

                THEN COALESCE(
                    amount,
                    0
                )

                ELSE 0

            END
        )
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount

FROM dbo.stg_payments;
GO


/* ============================================================
   10. PAYMENT FAILURE BY CUSTOMER
   ============================================================ */

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
    ) AS FailedPayments,

    CAST(
        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(p.payment_status)
                    )
                ) = 'failed'

                THEN COALESCE(
                    p.amount,
                    0
                )

                ELSE 0

            END
        )
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount

FROM dbo.stg_orders AS o

INNER JOIN dbo.stg_payments AS p
    ON o.order_id = p.order_id

WHERE
    o.customer_id IS NOT NULL

GROUP BY
    o.customer_id

HAVING
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
    ) > 0

ORDER BY
    FailedPaymentAmount DESC;
GO


/* ============================================================
   11. CANCELLED ORDERS WITH PAYMENT FAILURES
   ============================================================ */

SELECT

    COUNT(
        DISTINCT o.order_id
    ) AS CancelledOrdersWithPaymentFailure,

    CAST(
        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(o.order_status)
                    )
                ) = 'cancelled'

                AND LOWER(
                    LTRIM(
                        RTRIM(p.payment_status)
                    )
                ) = 'failed'

                THEN COALESCE(
                    p.amount,
                    0
                )

                ELSE 0

            END
        )
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount

FROM dbo.stg_orders AS o

INNER JOIN dbo.stg_payments AS p
    ON o.order_id = p.order_id

WHERE
    LOWER(
        LTRIM(
            RTRIM(o.order_status)
        )
    ) = 'cancelled';
GO


/* ============================================================
   12. ORDER-LEVEL REVENUE OUTCOME
   ============================================================

   This creates one analytical view of each order:

        Cancelled
        Non-Cancelled
        Payment Failed
        Payment Successful

   It helps avoid double-counting revenue when combining
   orders and payment transactions.
   ============================================================ */

WITH PaymentSummary AS
(
    SELECT

        order_id,

        MAX(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'successful'

                THEN 1

                ELSE 0

            END
        ) AS HasSuccessfulPayment,

        MAX(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'failed'

                THEN 1

                ELSE 0

            END
        ) AS HasFailedPayment,

        SUM(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'failed'

                THEN COALESCE(
                    amount,
                    0
                )

                ELSE 0

            END
        ) AS FailedPaymentAmount

    FROM dbo.stg_payments

    GROUP BY
        order_id
)

SELECT

    o.order_id,

    o.customer_id,

    o.order_status,

    CAST(
        o.revenue
        AS DECIMAL(18,2)
    ) AS OrderRevenue,

    COALESCE(
        p.HasSuccessfulPayment,
        0
    ) AS HasSuccessfulPayment,

    COALESCE(
        p.HasFailedPayment,
        0
    ) AS HasFailedPayment,

    CAST(
        COALESCE(
            p.FailedPaymentAmount,
            0
        )
        AS DECIMAL(18,2)
    ) AS FailedPaymentAmount,

    CASE

        WHEN LOWER(
            LTRIM(
                RTRIM(o.order_status)
            )
        ) = 'cancelled'

            THEN 'Cancelled'

        WHEN COALESCE(
            p.HasSuccessfulPayment,
            0
        ) = 1

            THEN 'Realised'

        WHEN COALESCE(
            p.HasFailedPayment,
            0
        ) = 1

            THEN 'Payment Risk'

        ELSE
            'Other'

    END AS RevenueOutcome

FROM dbo.stg_orders AS o

LEFT JOIN PaymentSummary AS p
    ON o.order_id = p.order_id;
GO


/* ============================================================
   13. REVENUE OUTCOME SUMMARY
   ============================================================ */

WITH PaymentSummary AS
(
    SELECT

        order_id,

        MAX(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'successful'

                THEN 1

                ELSE 0

            END
        ) AS HasSuccessfulPayment,

        MAX(
            CASE

                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'failed'

                THEN 1

                ELSE 0

            END
        ) AS HasFailedPayment

    FROM dbo.stg_payments

    GROUP BY
        order_id
),

RevenueOutcome AS
(
    SELECT

        o.order_id,

        o.revenue,

        CASE

            WHEN LOWER(
                LTRIM(
                    RTRIM(o.order_status)
                )
            ) = 'cancelled'

                THEN 'Cancelled'

            WHEN COALESCE(
                p.HasSuccessfulPayment,
                0
            ) = 1

                THEN 'Realised'

            WHEN COALESCE(
                p.HasFailedPayment,
                0
            ) = 1

                THEN 'Payment Risk'

            ELSE
                'Other'

        END AS RevenueOutcome

    FROM dbo.stg_orders AS o

    LEFT JOIN PaymentSummary AS p
        ON o.order_id = p.order_id
)

SELECT

    RevenueOutcome,

    COUNT(
        DISTINCT order_id
    ) AS Orders,

    CAST(
        SUM(
            COALESCE(
                revenue,
                0
            )
        )
        AS DECIMAL(18,2)
    ) AS RevenueAmount

FROM RevenueOutcome

GROUP BY
    RevenueOutcome

ORDER BY
    RevenueAmount DESC;
GO


/* ============================================================
   14. FINAL REVENUE LOSS CALCULATION
   ============================================================ */

WITH RevenueMetrics AS
(
    SELECT

        SUM(
            COALESCE(
                revenue,
                0
            )
        ) AS TotalRevenue,

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
        ) AS CancelledRevenue

    FROM dbo.stg_orders
)

SELECT

    CAST(
        TotalRevenue
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    CAST(
        CancelledRevenue
        AS DECIMAL(18,2)
    ) AS CalculatedRevenueLoss,

    CAST(
        2500000
        AS DECIMAL(18,2)
    ) AS ApprovedProjectRevenueLoss,

    CAST(
        CancelledRevenue - 2500000
        AS DECIMAL(18,2)
    ) AS DifferenceFromApprovedValue,

    CASE

        WHEN ABS(
            CancelledRevenue - 2500000
        ) < 1

            THEN 'PASS'

        ELSE
            'CHECK SOURCE BUSINESS RULE'

    END AS RevenueLossValidation

FROM RevenueMetrics;
GO


/* ============================================================
   15. REVENUE LOSS BY CUSTOMER RISK SIGNAL
   ============================================================ */

WITH CustomerRevenueRisk AS
(
    SELECT

        customer_id,

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
        ) AS CancelledRevenue,

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
)

SELECT

    CASE

        WHEN CancelledOrders = 0
            THEN 'No Cancellation Revenue Risk'

        WHEN CancelledOrders = 1
            THEN 'Low Revenue Risk'

        WHEN CancelledOrders BETWEEN 2 AND 3
            THEN 'Medium Revenue Risk'

        WHEN CancelledOrders >= 4
            THEN 'High Revenue Risk'

        ELSE
            'Unknown'

    END AS RevenueRiskSegment,

    COUNT(*) AS CustomerCount,

    CAST(
        SUM(
            CancelledRevenue
        )
        AS DECIMAL(18,2)
    ) AS RevenueAtRisk

FROM CustomerRevenueRisk

GROUP BY

    CASE

        WHEN CancelledOrders = 0
            THEN 'No Cancellation Revenue Risk'

        WHEN CancelledOrders = 1
            THEN 'Low Revenue Risk'

        WHEN CancelledOrders BETWEEN 2 AND 3
            THEN 'Medium Revenue Risk'

        WHEN CancelledOrders >= 4
            THEN 'High Revenue Risk'

        ELSE
            'Unknown'

    END

ORDER BY
    RevenueAtRisk DESC;
GO


/* ============================================================
   16. REVENUE LOSS SUMMARY
   ============================================================ */

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

    CAST(
        SUM(
            COALESCE(
                revenue,
                0
            )
        )
        AS DECIMAL(18,2)
    ) AS TotalRevenue,

    CAST(
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
        )
        AS DECIMAL(18,2)
    ) AS CalculatedRevenueLoss,

    CAST(
        2500000
        AS DECIMAL(18,2)
    ) AS ApprovedRevenueLoss

FROM dbo.stg_orders;
GO


/*
    ============================================================
    BUSINESS INTERPRETATION
    ============================================================

    Approved Project Story:

        Total Orders          = 40,000
        Cancelled Orders      = 13,381
        Cancellation Rate     = 33.45%
        Revenue Loss          = ₹2.5M

    Revenue loss is analysed through:

        1. Cancelled order revenue
        2. Revenue loss by month
        3. Revenue loss by channel
        4. Revenue loss by customer
        5. Failed payment exposure
        6. Payment + cancellation overlap

    IMPORTANT:

        Do not double-count the same order's revenue when
        joining payment transactions because one order can
        have multiple payment attempts.

    The final ₹2.5M value should reconcile with the defined
    project business rule.

    Next stage:

        Customer Behaviour
              +
        Cancellation Behaviour
              +
        Payment Risk
              +
        Revenue Risk
              +
        90-Day Inactivity
                    ↓
        Final Customer Risk Segmentation
                    ↓
             2,389 At-Risk Customers
    ============================================================
*/