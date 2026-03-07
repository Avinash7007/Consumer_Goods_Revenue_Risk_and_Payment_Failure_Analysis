# Consumer Goods Sales Analysis — SQL Analytics

SQL analytics on 1L+ transactions — churn, cancellation, returns, payment reconciliation | T-SQL


**Domain:** Consumer Goods / Retail &nbsp;|&nbsp; **Database:** Microsoft SQL Server (T-SQL) &nbsp;|&nbsp; **Period:** Jan 2022 – Dec 2025

---

## Business Context

A mid-size consumer goods distributor operating across 4 regions had no consolidated view of its sales, customer, and supply chain data. Raw data was siloed across 9 source systems with no standardised reporting layer. Management was unable to answer recurring questions raised every week in ops reviews:

> *"Revenue has been flat for 3 years — what is actually happening at the segment level?"*
>
> *"33% of our orders are cancelling — is this a channel problem or a process problem?"*
>
> *"Customers are going silent — we have no system to catch churn before it happens."*
>
> *"We are losing money on returns and failed payments — but we don't know where or why."*

This project built a structured SQL analytics layer across all 9 source files to answer these questions — replacing ad hoc Excel reporting with repeatable, production-ready queries.

---

## Dataset Overview

| Table | Rows | Description |
|---|---|---|
| `Fact_Sales` | 1,00,140 | Orders, revenue, quantity, discount |
| `Fact_Shipment` | 59,950 | Ship date, delivery date, ship mode, delivery status |
| `Fact_Returns` | 9,037 | Return reason, refund amount, return date |
| `Fact_Payments` | 60,079 | Payment method, status (Completed / Failed / Refunded) |
| `Dim_Order` | 40,000 | Order channel, status, priority |
| `Dim_Customer` | 5,000 | Customer master — region mapping |
| `Dim_Product` | 500 | Category, sub-category, brand, supplier |
| `Dim_Region` | 4 | North, South, East, West |
| `Dim_Supplier` | 50 | 50 suppliers across 44 countries |
| `Dim_Date` | 1,461 | Full date dimension — 2022 to 2025 |

---

## Key Business Metrics

| Metric | Value |
|---|---|
| Total Revenue (2022–2025) | ₹31.38 Crore |
| Average Order Value | ₹7,844 |
| Average Discount | 15% |
| Return Rate | 15% — 6,000 of 40,000 orders |
| Order Cancellation Rate | 33.5% — 13,381 of 40,000 orders |
| Failed Payment Rate | 33.5% of all transactions |
| Revenue at Risk | ₹20.96 Cr (Failed + Refunded payments) |
| Net Realised Revenue | ₹10.42 Cr (33% of gross) |
| Active Customers | 4,998 &nbsp;\|&nbsp; Products: 500 &nbsp;\|&nbsp; Suppliers: 50 |

---

## Problem 1 — Revenue Flat for 4 Consecutive Years

**Situation:** Revenue stayed between ₹7.77 Cr and ₹7.96 Cr every year from 2022 to 2025. Management assumed seasonal dips but had no data to confirm direction or cause.

**Analysis:** YoY, QoQ, and MoM growth queries showed the decline was consistent across all quarters — not seasonal. Category-level YoY breakdown revealed a silent product mix shift. Cumulative revenue by category identified which categories were losing share year over year while total order volumes remained steady.

**Output:** Category-level revenue breakdown replaced a blanket "flat revenue" narrative with actionable segment-level insight — giving the sales team a clear picture of where promotional support was needed.

```sql
WITH yr_tab AS (
    SELECT YEAR(Order_Date) AS yr,
           ROUND(SUM(Sales_Amount), 2) AS yearly_revenue
    FROM Fact_Sales
    GROUP BY YEAR(Order_Date)
),
yoy_tab AS (
    SELECT yr, yearly_revenue,
           LAG(yearly_revenue) OVER (ORDER BY yr) AS prev_yr_revenue
    FROM yr_tab
)
SELECT yr, yearly_revenue,
    ROUND((yearly_revenue - prev_yr_revenue) * 100.0
          / NULLIF(prev_yr_revenue, 0), 2) AS yoy_pct
FROM yoy_tab
ORDER BY yr;
```

---

## Problem 2 — 33.5% Order Cancellation Rate With No Visibility

**Situation:** 13,381 of 40,000 orders were cancelled — a rate that was unknown to the business until this analysis. No breakdown existed by channel, priority, or trend.

**Analysis:** Cancellation rate by channel (Online / Store / Mobile App) and by priority (Low / Medium / High) showed equal distribution across all dimensions — confirming a systemic process issue, not a channel-specific one. Monthly trend query revealed whether cancellations were improving or worsening. Revenue associated with cancelled orders was quantified for the first time.

**Output:** Identified that no single channel or priority was responsible — escalated to the operations team for root cause investigation at the fulfilment process level.

---

## Problem 3 — Customer Churn With No Early Warning System

**Situation:** The business had no mechanism to identify customers going inactive. By the time a customer was noticed as lost, re-engagement was already too late.

**Analysis:** Built a 3-tier activity classification using last order date — Active (< 90 days), At Risk (90–365 days), Churned (> 365 days). Monthly churn trend showed when acceleration was happening. New vs returning customer revenue split confirmed that returning customer revenue was declining faster than new acquisition could offset.

**Output:** A weekly-refreshable at-risk customer list enabling targeted re-engagement before customers fully churn — a capability the business had never had.

```sql
WITH last_order_tab AS (
    SELECT c.Customer_ID, c.Customer_Name,
           MAX(s.Order_Date) AS last_order_date
    FROM Dim_Customer AS c
    INNER JOIN Fact_Sales AS s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID, c.Customer_Name
)
SELECT Customer_ID, Customer_Name, last_order_date,
    DATEDIFF(DAY, last_order_date, GETDATE()) AS days_inactive,
    CASE
        WHEN DATEDIFF(DAY, last_order_date, GETDATE()) < 90   THEN 'Active'
        WHEN DATEDIFF(DAY, last_order_date, GETDATE()) <= 365 THEN 'At Risk'
        ELSE 'Churned'
    END AS customer_status
FROM last_order_tab
ORDER BY days_inactive DESC;
```

---

## Problem 4 — 15% Return Rate With No Root Cause Tracking

**Situation:** 9,037 returns across 40,000 orders — but no one knew why. Return reasons were being logged but never analysed.

**Analysis:** Return reason breakdown showed Late Delivery, Wrong Item, Damaged, and No Reason each at ~25%. Cross-referencing returns with shipment data confirmed that delayed orders had a higher return rate — directly linking logistics performance to return volume. Return rate was further analysed by region and product category.

**Output:** Shifted management focus from product quality (assumed cause) to delivery SLA enforcement (actual cause) — a finding the business had not previously identified.

---

## Problem 5 — ₹20.96 Cr Revenue at Risk From Payment Failures

**Situation:** Finance flagged a gap between expected and collected revenue. No breakdown of failed payments by channel or customer existed.

**Analysis:** Payment status showed a near-equal three-way split — Completed: 33%, Failed: 33.5%, Refunded: 33.5%. Failure rate by method (Credit Card / COD / UPI / Net Banking) was equal across all four — indicating a systemic issue. Top customers with repeated failures were flagged for priority follow-up.

**Output:** Net realised revenue of ₹10.42 Cr vs gross ₹31.38 Cr quantified the gap for the first time. Finance received a structured customer-level reconciliation list.

---

## Analysis Structure

| Section | Queries | Coverage |
|---|---|---|
| 1 — Data Validation | 7 | NULL checks, orphan records, date range, sanity flags |
| 2 — Revenue Trends | 8 | YoY, QoQ, MoM, category mix, region, rolling 30-day, cumulative YTD |
| 3 — Cancellation | 5 | By channel, priority, monthly trend, revenue impact |
| 4 — Churn & Retention | 9 | Classification, churn rate, monthly trend, CLV, Pareto, repeat rate |
| 5 — Returns | 7 | Reason breakdown, region, category, delivery linkage, top products |
| 6 — Payment Recon | 5 | Status breakdown, method failure rate, realisation gap, monthly trend |
| 7 — Shipment | 4 | Delivery time by mode, delay by region, delay-to-return causality |
| 8 — Product & Supplier | 5 | Category revenue, top products, per-category ranking, supplier contribution |
| 9 — Segmentation | 4 | Platinum/Gold/Silver/Regular, segment summary, percentile, loyalty |

---

## Key Findings

- **Revenue flat 4 years** — ₹7.85 Cr (2022) → ₹7.77 Cr (2025) — category mix shift identified as root cause, not demand decline
- **33.5% cancellation rate** — evenly spread across all channels and priorities — systemic process issue, not channel-specific
- **Churn accelerating** — 2,389 At-Risk customers, 681 already churned — returning customer revenue declining YoY
- **Return root cause** — Late Delivery is the top return reason — logistics problem, not product quality
- **Payment gap** — Only ₹10.42 Cr of ₹31.38 Cr gross revenue actually realised — ₹20.96 Cr at risk
- **Pareto confirmed** — Top 20% customers drive ~80% of revenue — highest retention ROI in this cohort

---

## Production Patterns Applied

```sql
-- Dynamic dates — no hardcoding
WHERE last_order_date <= DATEADD(DAY, -90, GETDATE())

-- Safe division — zero-divide protection
ROUND(SUM(Sales_Amount) / NULLIF(COUNT(DISTINCT Order_ID), 0), 2)

-- NULL-safe aggregation
ISNULL(SUM(Sales_Amount), 0)

-- Month-start truncation for consistent time grouping
DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1)

-- Running total with explicit window frame
SUM(daily_revenue) OVER (ORDER BY Order_Date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- Percentile-based segmentation
PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY total_revenue) OVER()

-- DENSE_RANK via CTE — avoids window + GROUP BY conflict in T-SQL
WITH agg_tab AS (SELECT ... GROUP BY ...)
SELECT *, DENSE_RANK() OVER (ORDER BY total_revenue DESC) FROM agg_tab
```

---

## Files

| File | Description |
|---|---|
| `consumer_goods_analysis.sql` | Complete SQL file — 54 queries across 9 sections |
| `README.md` | Project documentation |

> Source data is confidential and not included in this repository.

---

## Tech Stack

| Tool | Usage |
|---|---|
| SQL Server (T-SQL) | Query engine |
| SSMS | Development and execution |
| CTEs | Multi-step business logic |
| Window Functions | LAG, LEAD, DENSE_RANK, SUM OVER, AVG OVER, PERCENTILE_DISC, PERCENT_RANK |
| CASE expressions | Conditional aggregation and segmentation |
| Dynamic parameters | DECLARE — parameterised thresholds |

---

## Author

**Avinash Dubey** — Data Analyst | 3 Years Experience | NCR
📧 dubeyavinash157@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/avinash7007/) &nbsp;|&nbsp; [Portfolio](https://codebasics.io/portfolio/Avinash-Dubey) &nbsp;|&nbsp; [GitHub](https://github.com/Avinash7007)
