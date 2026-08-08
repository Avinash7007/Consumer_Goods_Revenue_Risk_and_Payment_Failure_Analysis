"""
Customer Churn & Revenue Risk Analysis
Python / Pandas - Data Cleaning
"""

import pandas as pd


def clean_orders(df: pd.DataFrame) -> pd.DataFrame:
    """Clean order-level data before SQL analysis."""
    result = df.copy()

    result.columns = (
        result.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
    )

    if "order_id" in result.columns:
        result["order_id"] = result["order_id"].astype("string").str.strip()

    if "customer_id" in result.columns:
        result["customer_id"] = result["customer_id"].astype("string").str.strip()

    if "order_date" in result.columns:
        result["order_date"] = pd.to_datetime(
            result["order_date"], errors="coerce"
        )

    for column in ["revenue", "sales_amount", "payment_amount"]:
        if column in result.columns:
            result[column] = pd.to_numeric(result[column], errors="coerce")

    result = result.drop_duplicates()

    return result


def clean_text_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Standardize text fields while preserving null values."""
    result = df.copy()

    for column in result.select_dtypes(include=["object", "string"]).columns:
        result[column] = result[column].astype("string").str.strip()

    return result
