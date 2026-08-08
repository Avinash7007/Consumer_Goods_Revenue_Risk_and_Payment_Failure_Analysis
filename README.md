# Consumer Goods Customer Churn & Revenue Risk Analysis

An end-to-end **Data Analyst project** focused on identifying cancellation behaviour, payment-failure signals, customer churn risk, and revenue loss using **Python/Pandas and SQL Server (T-SQL)**.

The project follows a practical analytics workflow: profile and clean source data with Python, validate the prepared data in SQL Server, perform customer/order/payment analysis, calculate cancellation-related revenue loss, and identify customers requiring retention attention.

> **Data privacy:** The original source dataset is confidential and is intentionally **not included** in this public repository. No customer-level records, company source files, credentials, or proprietary extracts are published.

---

## 1. Business Problem

The business was experiencing a high volume of order cancellations and payment failures but lacked a structured view of the customers and behaviours contributing to revenue risk.

The analysis was designed to answer:

1. How many orders were processed and cancelled?
2. What was the overall cancellation rate?
3. How much revenue was lost through cancelled orders?
4. Which customers showed stronger risk signals?
5. Which customers should the retention team prioritize?
6. How should customer churn be defined consistently?

---

## 2. Project Workflow

```text
Private Source Data
        |
        v
Python / Pandas
        |
        +--> Data Loading
        +--> Data Profiling
        +--> Data Cleaning
        +--> Data Standardization
        +--> Data Quality Checks
        |
        v
SQL Server / T-SQL
        |
        +--> Data Validation
        +--> Order Analysis
        +--> Cancellation Analysis
        +--> Customer Behaviour Analysis
        +--> Payment Risk Analysis
        +--> Revenue Loss Analysis
        +--> Customer Risk Segmentation
        +--> 90-Day Churn Analysis
        +--> Final KPI Reconciliation
        |
        v
Business Risk Insights
        |
        +--> 33.45% Cancellation Rate
        +--> 2.5M Revenue Loss
        +--> 2,389 At-Risk Customers
        +--> 90-Day Churn Definition
```

---

## 3. Final Project Metrics

| Metric | Final Value |
|---|---:|
| **Total Orders** | **40,000** |
| **Cancelled Orders** | **13,381** |
| **Cancellation Rate** | **33.45%** |
| **Revenue Loss from Cancelled Orders** | **2.5M** |
| **At-Risk Customers** | **2,389** |
| **Churn Definition** | **90 days of inactivity** |
| **Customer Records in Source Data** | **15,000** |
| **Payment Records in Source Data** | **40,000** |

> **Important:** `2.5M` is the approved project-level revenue-loss outcome. It is **not** presented as total company revenue. The SQL analysis calculates cancellation-related revenue loss from the source data and uses the final validation layer for reconciliation.

---

## 4. Python / Pandas Layer

Python was used for **data preparation and quality control**, not for a predictive ML model.

### Responsibilities

- Load approved local source files
- Profile dataset shape and structure
- Inspect missing values and duplicates
- Standardize column names
- Standardize text/status fields
- Convert date columns to consistent datetime values
- Convert numeric fields to appropriate numeric types
- Remove duplicate records
- Validate required columns before downstream analysis

### Python workflow

```text
01_data_loading.py
        |
        v
02_data_cleaning.py
        |
        v
03_data_standardization.py
        |
        v
04_data_quality_checks.py
```

The local source data is deliberately excluded from GitHub. The Python scripts are reusable preparation logic that can be executed against authorized local data.

---

## 5. SQL Server / T-SQL Analysis Layer

The SQL layer contains the core business analysis and is organized by analytical question rather than one large query file.

```text
sql/
├── 01_data_validation.sql
├── 02_order_analysis.sql
├── 03_cancellation_analysis.sql
├── 04_customer_behaviour.sql
├── 05_payment_risk_analysis.sql
├── 06_revenue_loss_analysis.sql
├── 07_customer_risk_segmentation.sql
├── 08_churn_analysis.sql
└── 09_final_validation.sql
```

### Analysis sequence

| Step | Analysis | Purpose |
|---|---|---|
| 01 | Data Validation | Validate row counts, keys, nulls, duplicates, dates, and orphan records |
| 02 | Order Analysis | Analyze order volume, frequency, repeat behaviour, and purchase patterns |
| 03 | Cancellation Analysis | Calculate cancelled orders, cancellation rate, channel trends, and cancellation signals |
| 04 | Customer Behaviour | Analyze first/last orders, purchase gaps, frequency, and customer activity |
| 05 | Payment Risk | Analyze payment status, failed payments, and customer-level payment risk |
| 06 | Revenue Loss | Calculate revenue associated with cancelled orders and related risk measures |
| 07 | Customer Risk Segmentation | Combine behavioural signals to prioritize at-risk customers |
| 08 | Churn Analysis | Apply the official 90-day inactivity churn definition |
| 09 | Final Validation | Reconcile final project KPIs and verify the risk model output |

---

## 6. Cancellation Analysis

The final SQL analysis produces:

- **40,000 total orders**
- **13,381 cancelled orders**
- **33.45% cancellation rate**
- **2.5M revenue loss from cancelled orders**

Cancellation rate is calculated as:

```text
Cancelled Orders / Total Orders × 100

13,381 / 40,000 × 100 = 33.45%
```

The revenue-loss metric is calculated from the cancelled-order revenue in SQL rather than being manually inserted into the analytical query.

---

## 7. Customer Risk Segmentation

The **2,389 at-risk customers are not simply the customers who have been inactive for 90 days**.

The project combines multiple behavioural signals:

- Customer inactivity / days since last order
- Cancellation behaviour
- Payment failures
- Purchase frequency and behaviour

This creates a broader **at-risk** population that can be prioritized before every customer reaches the formal churn threshold.

### Risk concept

```text
Customer Behaviour
       |
       +--> Inactivity Signal
       +--> Cancellation Signal
       +--> Payment Failure Signal
       +--> Purchase Behaviour Signal
       |
       v
Customer Risk Score / Segment
       |
       v
Retention Priority
```

Final approved output:

> **2,389 customers identified as at-risk.**

---

## 8. Churn Definition

The project uses a separate, explicit churn rule:

> **Churn = 90 days of customer inactivity.**

The 90-day threshold is used to reduce false churn flags caused by normal short purchase gaps or longer customer purchase cycles.

The project also compares shorter inactivity windows during analysis so stakeholders can understand how the churn definition changes the result.

**Important distinction:**

- **At-Risk** = broader multi-signal risk classification.
- **Churned** = customer meeting the **90-day inactivity** definition.

These two populations should not be presented as the same metric.

---

## 9. Key SQL Techniques

The project demonstrates practical SQL Server / T-SQL techniques including:

- `JOIN` and `LEFT JOIN`
- `GROUP BY` and aggregations
- `CASE` expressions
- CTEs
- `COUNT(DISTINCT ...)`
- Conditional aggregation
- `DATEDIFF`
- `LAG()` for customer purchase-gap analysis
- `DENSE_RANK()` for ranking
- Customer-level segmentation
- KPI reconciliation
- Data-quality validation
- Orphan-key checks
- Null and duplicate checks

---

## 10. Data Validation Approach

The project validates the analysis before reporting the final KPIs.

### Validation checks include

- Dataset row counts
- Required-field null checks
- Duplicate order/customer/payment IDs
- Orphan orders and customers
- Invalid or negative amounts
- Future-dated orders
- Status distributions
- Cancellation KPI reconciliation
- Revenue-loss reconciliation
- 90-day churn validation
- At-risk customer count validation

The final validation layer is designed to return **PASS** or **CHECK** instead of silently forcing the result to match an expected number.

---

## 11. Data Privacy

The original dataset is **not uploaded to GitHub**.

The public repository contains only:

- Python/Pandas data-preparation logic
- SQL Server/T-SQL analysis
- Data-quality and validation logic
- Documentation
- Non-sensitive project-level KPI definitions

The repository does **not** contain:

- Customer-level records
- Raw CSV/Excel exports
- Personally identifiable information
- Payment details
- Company source-system extracts
- Database credentials
- API keys or passwords

Authorized source files can be placed locally under `dataset/`. They are excluded from Git tracking through `.gitignore`.

---

## 12. Repository Structure

```text
Consumer_Goods_Revenue_Risk_and_Payment_Failure_Analysis/
|
├── python/
│   ├── 01_data_loading.py
│   ├── 02_data_cleaning.py
│   ├── 03_data_standardization.py
│   └── 04_data_quality_checks.py
│
├── sql/
│   ├── 01_data_validation.sql
│   ├── 02_order_analysis.sql
│   ├── 03_cancellation_analysis.sql
│   ├── 04_customer_behaviour.sql
│   ├── 05_payment_risk_analysis.sql
│   ├── 06_revenue_loss_analysis.sql
│   ├── 07_customer_risk_segmentation.sql
│   ├── 08_churn_analysis.sql
│   └── 09_final_validation.sql
│
├── dataset/
│   └── README.md
│
├── .gitignore
├── requirements.txt
└── README.md
```

---

## 13. Tech Stack

| Technology | Purpose |
|---|---|
| **Python** | Data preparation and quality checks |
| **Pandas** | Cleaning, standardization, profiling |
| **SQL Server** | Analytical data processing |
| **T-SQL** | Business analysis and KPI calculations |
| **SSMS** | SQL development and validation |
| **Git / GitHub** | Version control and project documentation |

---

## 14. Interview Project Story

> The business was facing rising order cancellations and limited visibility into customers who were becoming risky. I used Python and Pandas for data profiling, cleaning, standardization, and quality checks, then used SQL Server and T-SQL for the core business analysis. I analyzed 40,000 orders, identified 13,381 cancelled orders, calculated a 33.45% cancellation rate, and quantified 2.5M in cancellation-related revenue loss. I then combined inactivity, cancellation behaviour, payment failures, and purchase behaviour to identify 2,389 at-risk customers. Separately, I defined customer churn as 90 days of inactivity so the business had a consistent retention and churn framework.

This project was focused on **SQL-based business analysis and Python/Pandas data preparation**, not dashboard development or predictive machine learning.

---

## Author

**Avinash Dubey — Data Analyst**

- LinkedIn: https://www.linkedin.com/in/avinash7007/
- Portfolio: https://avinash7007.github.io/avinash-portfolio/
- GitHub: https://github.com/Avinash7007
