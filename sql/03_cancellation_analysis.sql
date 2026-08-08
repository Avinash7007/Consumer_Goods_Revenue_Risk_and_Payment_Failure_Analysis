/*
    ============================================================
    PROJECT 2
    Customer Churn & Revenue Risk Analysis
    ============================================================

    File:
        03_cancellation_analysis.sql

    Purpose:
        Analyze order cancellation behaviour and identify
        cancellation patterns that contribute to customer
        and revenue risk.

    Source:
        dbo.stg_orders

    Technology:
        SQL Server / T-SQL

    Approved Project Metrics:
        Total Orders          = 40,000
        Cancelled Orders     = 13,381
        Cancellation Rate    = 33.45%
        Revenue Loss         = ₹2.5M

    Important:
        Revenue Loss is calculated from the source data.
        It is NOT hard-coded into the analysis.
*/


USE YOUR_DATABASE_NAME;
GO


/* ============================================================
   1. OVERALL CANCELLATION KPI
   ============================================================ */

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
    ) AS CancelledOrders,

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
    ) AS CancellationRate

FROM dbo.stg_orders;
GO


/* ============================================================
   2. APPROVED KPI RECONCILIATION
   ============================================================ */

WITH CancellationMetrics AS
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
    ) AS CancellationRate,

    CASE
        WHEN TotalOrders = 40000
            THEN 'PASS'
        ELSE 'CHECK'
    END AS TotalOrdersValidation,

    CASE
        WHEN CancelledOrders = 13381
            THEN 'PASS'
        ELSE 'CHECK'
    END AS CancelledOrdersValidation,

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
        ELSE 'CHECK'
    END AS CancellationRateValidation

FROM CancellationMetrics;
GO


/* ============================================================
   3. CANCELLATION BY ORDER CHANNEL
   ============================================================ */

SELECT
    order_channel AS OrderChannel,

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
    ) AS CancellationRate

FROM dbo.stg_orders

WHERE order_channel IS NOT NULL

GROUP BY
    order_channel

ORDER BY
    CancellationRate DESC;
GO


/* ============================================================
   4. CHANNEL RECONCILIATION
   ============================================================ */

WITH ChannelMetrics AS
(
    SELECT
        order_channel,

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

    WHERE order_channel IS NOT NULL

    GROUP BY
        order_channel
)

SELECT
    order_channel AS OrderChannel,

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
    ) AS CancellationRate

FROM ChannelMetrics

ORDER BY
    TotalOrders DESC;
GO


/* ============================================================
   5. MONTHLY CANCELLATION TREND
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
    ) AS CancellationRate

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
   6. YEARLY CANCELLATION TREND
   ============================================================ */

SELECT
    YEAR(order_date) AS OrderYear,

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
    ) AS CancellationRate

FROM dbo.stg_orders

WHERE order_date IS NOT NULL

GROUP BY
    YEAR(order_date)

ORDER BY
    OrderYear;
GO


/* ============================================================
   7. CUSTOMER-LEVEL CANCELLATION BEHAVIOUR
   ============================================================ */

SELECT
    customer_id,

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
    ) AS CustomerCancellationRate

FROM dbo.stg_orders

WHERE customer_id IS NOT NULL

GROUP BY
    customer_id

ORDER BY
    CustomerCancellationRate DESC,

    CancelledOrders DESC;
GO


/* ============================================================
   8. CUSTOMERS WITH REPEATED CANCELLATIONS
   ============================================================ */

WITH CustomerCancellation AS
(
    SELECT
        customer_id,

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
)

SELECT
    customer_id,

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
    ) AS CancellationRate

FROM CustomerCancellation

WHERE CancelledOrders >= 2

ORDER BY
    CancelledOrders DESC,

    CancellationRate DESC;
GO


/* ============================================================
   9. HIGH CANCELLATION-RATE CUSTOMERS
   ============================================================ */

WITH CustomerCancellation AS
(
    SELECT
        customer_id,

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
)

SELECT
    customer_id,

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
    ) AS CancellationRate

FROM CustomerCancellation

WHERE
    TotalOrders >= 2

    AND
    (
        CancelledOrders * 100.0
        /
        NULLIF(
            TotalOrders,
            0
        )
    ) >= 50

ORDER BY
    CancellationRate DESC,

    CancelledOrders DESC;
GO


/* ============================================================
   10. CANCELLATION REVENUE IMPACT
   ============================================================

   Calculate revenue associated with cancelled orders.

   IMPORTANT:
   The final project Revenue Loss target is ₹2.5M.
   This query calculates the value from source data rather
   than hard-coding ₹2.5M.
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
    ) AS CancelledOrderRevenue

FROM dbo.stg_orders;
GO


/* ============================================================
   11. REVENUE LOSS AS % OF TOTAL ORDER REVENUE
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
   12. TOP CHANNELS BY CANCELLED REVENUE
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
    ) AS CancelledRevenue

FROM dbo.stg_orders

WHERE order_channel IS NOT NULL

GROUP BY
    order_channel

ORDER BY
    CancelledRevenue DESC;
GO


/* ============================================================
   13. CUSTOMER CANCELLATION RISK SIGNAL
   ============================================================ */

WITH CustomerCancellation AS
(
    SELECT
        customer_id,

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
)

SELECT
    customer_id,

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
    ) AS CancellationRate,

    CASE

        WHEN
            CancelledOrders >= 3
            AND
            (
                CancelledOrders * 100.0
                /
                NULLIF(
                    TotalOrders,
                    0
                )
            ) >= 50
            THEN 'High Cancellation Risk'

        WHEN
            CancelledOrders >= 2
            THEN 'Medium Cancellation Risk'

        WHEN
            CancelledOrders = 1
            THEN 'Low Cancellation Signal'

        ELSE
            'No Cancellation Signal'

    END AS CancellationRiskSignal

FROM CustomerCancellation

ORDER BY
    CancellationRate DESC,

    CancelledOrders DESC;
GO


/* ============================================================
   14. CANCELLATION STATUS BY CUSTOMER
   ============================================================ */

WITH CustomerCancellation AS
(
    SELECT
        customer_id,

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
)

SELECT

    CASE

        WHEN CancelledOrders = 0
            THEN 'No Cancellation'

        WHEN CancelledOrders = 1
            THEN 'Single Cancellation'

        WHEN CancelledOrders BETWEEN 2 AND 3
            THEN 'Repeated Cancellation'

        WHEN CancelledOrders >= 4
            THEN 'Frequent Cancellation'

        ELSE
            'Unknown'

    END AS CancellationSegment,

    COUNT(*) AS CustomerCount

FROM CustomerCancellation

GROUP BY

    CASE

        WHEN CancelledOrders = 0
            THEN 'No Cancellation'

        WHEN CancelledOrders = 1
            THEN 'Single Cancellation'

        WHEN CancelledOrders BETWEEN 2 AND 3
            THEN 'Repeated Cancellation'

        WHEN CancelledOrders >= 4
            THEN 'Frequent Cancellation'

        ELSE
            'Unknown'

    END

ORDER BY
    CustomerCount DESC;
GO


/* ============================================================
   15. FINAL CANCELLATION SUMMARY
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
            COUNT(
                DISTINCT order_id
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS CancellationRate,

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
    ) AS CalculatedRevenueLoss

FROM dbo.stg_orders;
GO


/*
    ============================================================
    BUSINESS INTERPRETATION
    ============================================================

    Approved project values:

        Total Orders       = 40,000
        Cancelled Orders   = 13,381
        Cancellation Rate  = 33.45%
        Revenue Loss       = ₹2.5M

    Customer cancellation behaviour is used later as one
    of the risk signals.

    At-Risk Customers are NOT calculated from cancellation
    behaviour alone.

    Final At-Risk classification combines:

        1. Inactivity
        2. Cancellation behaviour
        3. Payment failures
        4. Purchase behaviour

    Churn definition:

        90 days inactivity

    Therefore:

        Cancellation Risk
                +
        Inactivity Risk
                +
        Payment Risk
                +
        Customer Behaviour
                ↓
        Final Customer Risk Segmentation
    ============================================================
*/