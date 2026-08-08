/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        05_payment_risk_analysis.sql

    Purpose:
        Analyze payment failures and create payment-risk
        signals for customer risk segmentation.

    Source:
        dbo.stg_payments
        dbo.stg_orders

    Technology:
        SQL Server / T-SQL

    Project Context:
        Rising cancellations + payment failures
        were used to identify customers requiring
        retention attention.

    Approved Project KPI:
        At-Risk Customers = 2,389

    Important:
        The 2,389 count is NOT calculated from payment
        failures alone.
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. PAYMENT STATUS DISTRIBUTION
   ============================================================ */

SELECT
    LOWER(
        LTRIM(
            RTRIM(payment_status)
        )
    ) AS PaymentStatus,

    COUNT(
        DISTINCT payment_id
    ) AS PaymentCount,

    CAST(
        COUNT(
            DISTINCT payment_id
        ) * 100.0
        /
        NULLIF(
            COUNT(DISTINCT payment_id)
            OVER (),
            0
        )
        AS DECIMAL(10,2)
    ) AS PaymentPercentage

FROM dbo.stg_payments

GROUP BY
    LOWER(
        LTRIM(
            RTRIM(payment_status)
        )
    )

ORDER BY
    PaymentCount DESC;
GO


/* ============================================================
   2. TOTAL PAYMENT TRANSACTIONS
   ============================================================ */

SELECT
    COUNT(
        DISTINCT payment_id
    ) AS TotalPayments
FROM dbo.stg_payments;
GO


/* ============================================================
   3. FAILED PAYMENT COUNT
   ============================================================ */

SELECT
    COUNT(
        DISTINCT payment_id
    ) AS FailedPayments
FROM dbo.stg_payments

WHERE LOWER(
    LTRIM(
        RTRIM(payment_status)
    )
) = 'failed';
GO


/* ============================================================
   4. PAYMENT FAILURE RATE
   ============================================================ */

SELECT

    COUNT(
        DISTINCT
        CASE
            WHEN LOWER(
                LTRIM(
                    RTRIM(payment_status)
                )
            ) = 'failed'
            THEN payment_id
        END
    ) AS FailedPayments,

    COUNT(
        DISTINCT payment_id
    ) AS TotalPayments,

    CAST(
        COUNT(
            DISTINCT
            CASE
                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'failed'
                THEN payment_id
            END
        ) * 100.0
        /
        NULLIF(
            COUNT(DISTINCT payment_id),
            0
        )
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate

FROM dbo.stg_payments;
GO


/* ============================================================
   5. FAILED PAYMENT REVENUE / AMOUNT
   ============================================================ */

SELECT

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
   6. PAYMENT STATUS BY MONTH
   ============================================================ */

SELECT

    YEAR(payment_date) AS PaymentYear,

    MONTH(payment_date) AS PaymentMonth,

    DATENAME(
        MONTH,
        payment_date
    ) AS MonthName,

    COUNT(
        DISTINCT payment_id
    ) AS TotalPayments,

    COUNT(
        DISTINCT
        CASE
            WHEN LOWER(
                LTRIM(
                    RTRIM(payment_status)
                )
            ) = 'failed'
            THEN payment_id
        END
    ) AS FailedPayments,

    CAST(
        COUNT(
            DISTINCT
            CASE
                WHEN LOWER(
                    LTRIM(
                        RTRIM(payment_status)
                    )
                ) = 'failed'
                THEN payment_id
            END
        ) * 100.0
        /
        NULLIF(
            COUNT(DISTINCT payment_id),
            0
        )
        AS DECIMAL(10,2)
    ) AS FailureRate

FROM dbo.stg_payments

WHERE payment_date IS NOT NULL

GROUP BY

    YEAR(payment_date),

    MONTH(payment_date),

    DATENAME(
        MONTH,
        payment_date
    )

ORDER BY

    PaymentYear,

    PaymentMonth;
GO


/* ============================================================
   7. ORDER-LEVEL PAYMENT FAILURE SIGNAL
   ============================================================ */

SELECT

    order_id,

    COUNT(
        DISTINCT payment_id
    ) AS PaymentAttempts,

    COUNT(
        DISTINCT
        CASE
            WHEN LOWER(
                LTRIM(
                    RTRIM(payment_status)
                )
            ) = 'failed'
            THEN payment_id
        END
    ) AS FailedPaymentAttempts,

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

FROM dbo.stg_payments

WHERE order_id IS NOT NULL

GROUP BY
    order_id

ORDER BY
    FailedPaymentAttempts DESC;
GO


/* ============================================================
   8. ORDERS WITH REPEATED PAYMENT FAILURES
   ============================================================ */

SELECT

    order_id,

    COUNT(
        DISTINCT payment_id
    ) AS PaymentAttempts,

    COUNT(
        DISTINCT
        CASE
            WHEN LOWER(
                LTRIM(
                    RTRIM(payment_status)
                )
            ) = 'failed'
            THEN payment_id
        END
    ) AS FailedPaymentAttempts

FROM dbo.stg_payments

WHERE order_id IS NOT NULL

GROUP BY
    order_id

HAVING
    COUNT(
        DISTINCT
        CASE
            WHEN LOWER(
                LTRIM(
                    RTRIM(payment_status)
                )
            ) = 'failed'
            THEN payment_id
        END
    ) >= 2

ORDER BY
    FailedPaymentAttempts DESC;
GO


/* ============================================================
   9. CUSTOMER-LEVEL PAYMENT BEHAVIOUR
   ============================================================ */

SELECT

    o.customer_id,

    COUNT(
        DISTINCT p.payment_id
    ) AS TotalPaymentAttempts,

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

ORDER BY
    FailedPayments DESC;
GO


/* ============================================================
   10. CUSTOMER PAYMENT FAILURE RATE
   ============================================================ */

WITH CustomerPayments AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT p.payment_id
        ) AS TotalPaymentAttempts,

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
)

SELECT

    customer_id,

    TotalPaymentAttempts,

    FailedPayments,

    CAST(
        FailedPayments * 100.0
        /
        NULLIF(
            TotalPaymentAttempts,
            0
        )
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate

FROM CustomerPayments

ORDER BY
    PaymentFailureRate DESC,

    FailedPayments DESC;
GO


/* ============================================================
   11. CUSTOMERS WITH REPEATED PAYMENT FAILURES
   ============================================================ */

WITH CustomerPayments AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT p.payment_id
        ) AS TotalPaymentAttempts,

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
)

SELECT

    customer_id,

    TotalPaymentAttempts,

    FailedPayments,

    CAST(
        FailedPayments * 100.0
        /
        NULLIF(
            TotalPaymentAttempts,
            0
        )
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate

FROM CustomerPayments

WHERE
    FailedPayments >= 2

ORDER BY
    FailedPayments DESC,

    PaymentFailureRate DESC;
GO


/* ============================================================
   12. HIGH PAYMENT-RISK CUSTOMERS
   ============================================================ */

WITH CustomerPayments AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT p.payment_id
        ) AS TotalPaymentAttempts,

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
)

SELECT

    customer_id,

    TotalPaymentAttempts,

    FailedPayments,

    CAST(
        FailedPayments * 100.0
        /
        NULLIF(
            TotalPaymentAttempts,
            0
        )
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate,

    CASE

        WHEN
            FailedPayments >= 3
            AND
            (
                FailedPayments * 100.0
                /
                NULLIF(
                    TotalPaymentAttempts,
                    0
                )
            ) >= 50
            THEN 'High Payment Risk'

        WHEN
            FailedPayments >= 2
            THEN 'Medium Payment Risk'

        WHEN
            FailedPayments = 1
            THEN 'Payment Risk Signal'

        ELSE
            'No Payment Risk Signal'

    END AS PaymentRiskSignal

FROM CustomerPayments

ORDER BY
    FailedPayments DESC,

    PaymentFailureRate DESC;
GO


/* ============================================================
   13. PAYMENT RISK BY CUSTOMER REVENUE
   ============================================================ */

WITH CustomerPayments AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT p.payment_id
        ) AS TotalPaymentAttempts,

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

CustomerRevenue AS
(
    SELECT

        customer_id,

        SUM(
            COALESCE(
                revenue,
                0
            )
        ) AS TotalRevenue

    FROM dbo.stg_orders

    WHERE
        customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT

    cp.customer_id,

    cp.TotalPaymentAttempts,

    cp.FailedPayments,

    CAST(
        cp.FailedPayments * 100.0
        /
        NULLIF(
            cp.TotalPaymentAttempts,
            0
        )
        AS DECIMAL(10,2)
    ) AS PaymentFailureRate,

    CAST(
        cr.TotalRevenue
        AS DECIMAL(18,2)
    ) AS TotalRevenue

FROM CustomerPayments AS cp

LEFT JOIN CustomerRevenue AS cr
    ON cp.customer_id = cr.customer_id

ORDER BY
    cp.FailedPayments DESC,

    cr.TotalRevenue DESC;
GO


/* ============================================================
   14. FAILED PAYMENT CUSTOMERS WITH ORDER STATUS
   ============================================================ */

SELECT

    o.customer_id,

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
    FailedPayments DESC,

    CancelledOrders DESC;
GO


/* ============================================================
   15. COMBINED PAYMENT + CANCELLATION SIGNAL
   ============================================================ */

WITH CustomerRiskSignals AS
(
    SELECT

        o.customer_id,

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

    LEFT JOIN dbo.stg_payments AS p
        ON o.order_id = p.order_id

    WHERE
        o.customer_id IS NOT NULL

    GROUP BY
        o.customer_id
)

SELECT

    customer_id,

    TotalOrders,

    CancelledOrders,

    FailedPayments,

    CASE

        WHEN
            CancelledOrders > 0
            AND FailedPayments > 0
            THEN 'Cancellation + Payment Risk'

        WHEN
            CancelledOrders > 0
            THEN 'Cancellation Risk'

        WHEN
            FailedPayments > 0
            THEN 'Payment Risk'

        ELSE
            'No Risk Signal'

    END AS CombinedPaymentCancellationSignal

FROM CustomerRiskSignals

ORDER BY

    CASE

        WHEN
            CancelledOrders > 0
            AND FailedPayments > 0
            THEN 1

        WHEN
            CancelledOrders > 0
            THEN 2

        WHEN
            FailedPayments > 0
            THEN 3

        ELSE
            4

    END;
GO


/* ============================================================
   16. PAYMENT RISK SUMMARY
   ============================================================ */

WITH CustomerPaymentRisk AS
(
    SELECT

        o.customer_id,

        COUNT(
            DISTINCT p.payment_id
        ) AS TotalPaymentAttempts,

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
)

SELECT

    COUNT(*) AS CustomersWithPaymentActivity,

    SUM(
        CASE
            WHEN FailedPayments = 0
                THEN 1
            ELSE 0
        END
    ) AS CustomersWithoutPaymentFailure,

    SUM(
        CASE
            WHEN FailedPayments > 0
                THEN 1
            ELSE 0
        END
    ) AS CustomersWithPaymentFailure,

    SUM(
        CASE
            WHEN FailedPayments >= 2
                THEN 1
            ELSE 0
        END
    ) AS CustomersWithRepeatedPaymentFailures

FROM CustomerPaymentRisk;
GO


/*
    ============================================================
    BUSINESS INTERPRETATION
    ============================================================

    Payment failure is one of the customer-risk signals.

    This module produces:

        - Total payment attempts
        - Failed payments
        - Payment failure rate
        - Failed payment amount
        - Repeated payment failures
        - Customer-level payment risk
        - Payment + cancellation risk signal

    The final At-Risk customer population is NOT defined
    by payment failure alone.

    Final risk logic will combine:

        1. Customer inactivity
        2. Cancellation behaviour
        3. Payment failures
        4. Purchase behaviour

                         ↓

                  Risk Segmentation

                         ↓

                  2,389 At-Risk Customers

    Churn remains:

        90 days inactivity

    Revenue Loss remains:

        ₹2.5M

    Those project metrics are reconciled in the
    dedicated revenue-risk and final-validation modules.
    ============================================================
*/