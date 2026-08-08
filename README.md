# Consumer Goods Customer Churn & Revenue Risk Analysis

An end-to-end **Data Analyst project** focused on identifying customer churn signals, cancellation behaviour, payment failures, and revenue loss using **Python/Pandas and SQL Server (T-SQL)**.

The workflow cleans and standardizes source data in Python, validates it in SQL Server, analyzes order/customer/payment behaviour, and produces a prioritized customer-risk view for retention teams.

> **Data privacy:** The original source dataset is confidential and is intentionally **not included** in this public repository. No customer-level records, company source files, credentials, or proprietary extracts are published.

## Business Problem

The business was experiencing rising order cancellations and payment failures but did not have clear visibility into which customers were becoming risky.

The analysis was designed to answer:

1. How large is the cancellation problem?
2. How much revenue is exposed to cancellation-related loss?
3. Which customers show stronger churn-risk signals?
4. Which customers should the retention team prioritize?

## Project Workflow

```text
Private Source Data
        ↓
Python / Pandas
        ↓
Cleaning + Standardization + Data Quality Checks
        ↓
SQL Server / T-SQL
        ↓
Order Analysis
        ↓
Cancellation Analysis
        ↓
Customer Behaviour Analysis
        ↓
Payment Risk Analysis
        ↓
Revenue Loss Analysis
        ↓
Customer Risk Segmentation
        ↓
90-Day Churn Analysis
        ↓
Final Validation / KPI Reconciliation
        ↓
Business Risk Insights
```

## Final Project Metrics

| Metric | Final Value |
|---|---:|
| **Total Orders** | **40,000** |
| **Cancelled Orders** | **13,381** |
| **Cancellation Rate** | **33.45%** |
| **Revenue Loss** | **₹2.5M** |
| **At-Risk Customers** | **2,389** |
| **Churn Definition** | **90 days inactivity** |
| **Technology** | **SQL Server / T-SQL + Python / Pandas** |

These are the approved project-level metrics used consistently across the project documentation and interview story.

## Python / Pandas

Python was used for the data-preparation layer before SQL analysis.

- Load approved local source files
- Standardize column names
- Handle missing values and invalid date formats
- Remove duplicate records
- Standardize text/status fields
- Convert numeric fields to appropriate types
- Profile nulls, duplicates, unique values, and data types
- Perform basic data-quality checks before analysis

```text
python/
├── 01_data_loading.py
├── 02_data_cleaning.py
├── 03_data_standardization.py
└── 04_data_quality_checks.py
```

## SQL Server / T-SQL Analysis

The SQL layer is modular so each business question can be tested independently.

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

**01 — Data Validation** — required fields, duplicates, orphan keys, date ranges, invalid values, and baseline KPIs.

**02 — Order Analysis** — order volume, purchase frequency, repeat behaviour, order value, and purchase sequences.

**03 — Cancellation Analysis** — cancellation rate, trends, customer-level cancellation behaviour, and cancellation-related revenue impact.

**04 — Customer Behaviour** — first/last orders, purchase gaps, frequency, repeat behaviour, and activity patterns.

**05 — Payment Risk Analysis** — payment status, failed payments, customer payment-failure patterns, and risk signals.

**06 — Revenue Loss Analysis** — revenue loss calculated from the source-data business rule rather than manually entered.

**07 — Customer Risk Segmentation** — multiple behavioural signals combined to prioritize customers for retention.

**08 — Churn Analysis** — churn defined as **90 days of inactivity**, separately from the broader at-risk population.

**09 — Final Validation** — final QA and KPI reconciliation.

## At-Risk Customer Methodology

The **2,389 at-risk customers are not simply the customers who have been inactive for 90 days**.

The project combines:

- Customer inactivity / days since last order
- Cancellation behaviour
- Payment failures
- Purchase frequency and behaviour

This creates a broader risk view that can be used before a customer necessarily becomes churned.

### Churn definition

> **Churn = 90 days of customer inactivity.**

The 90-day rule avoids treating normal short-term gaps as churn where customers may have longer purchase cycles.

## Key SQL Techniques

- `JOIN` / `LEFT JOIN`
- `GROUP BY` and aggregations
- `CASE` expressions
- CTEs
- `COUNT(DISTINCT ...)`
- `DATEDIFF`
- `LAG()` for purchase-gap analysis
- `DENSE_RANK()` for customer ranking
- Conditional aggregation
- KPI reconciliation and data-quality checks

## Business Outcome

- **40,000 orders** were analyzed.
- **13,381 orders** were cancelled.
- The resulting **cancellation rate was 33.45%**.
- Cancellation-related analysis quantified approximately **₹2.5M in revenue loss**.
- **2,389 customers** were prioritized as at-risk based on combined behavioural signals.
- A **90-day inactivity rule** was established as the churn definition.

The output can support retention teams in prioritizing high-risk customers and investigating the operational causes behind cancellations and payment failures.

## Data Privacy & Confidentiality

The original dataset is **not uploaded to GitHub**.

This repository contains only analytical SQL logic, Python/Pandas data-preparation logic, documentation, and non-sensitive project-level KPI definitions.

The repository does **not** contain:

- Customer-level records
- Raw CSV/Excel exports
- Company source-system extracts
- Personally identifiable information
- Passwords/API keys/database credentials
- Confidential transaction-level data

Authorized users can place approved source files locally in `dataset/`. Those files are excluded from Git tracking.

## Repository Structure

```text
Consumer_Goods_Revenue_Risk_and_Payment_Failure_Analysis/
│
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

## Tech Stack

| Technology | Purpose |
|---|---|
| **Python** | Data preparation and quality checks |
| **Pandas** | Cleaning, standardization and profiling |
| **SQL Server** | Analytical data processing |
| **T-SQL** | Business analysis and KPI calculations |
| **SSMS** | SQL development and validation |
| **Git / GitHub** | Version control and documentation |

## Author

**Avinash Dubey — Data Analyst**

📧 dubeyavinash157@gmail.com  
💼 https://www.linkedin.com/in/avinash7007/  
🌐 https://avinash7007.github.io/avinash-portfolio/  
🐙 https://github.com/Avinash7007
