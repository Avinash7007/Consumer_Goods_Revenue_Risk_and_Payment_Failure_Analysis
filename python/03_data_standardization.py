"""
Customer Churn & Revenue Risk Analysis
Python / Pandas - Data Standardization
"""

import pandas as pd


def standardize_status_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Normalize categorical status fields for reliable SQL analysis."""
    result = df.copy()

    status_columns = [
        "order_status",
        "payment_status",
        "return_status",
        "customer_segment",
    ]

    for column in status_columns:
        if column in result.columns:
            result[column] = (
                result[column]
                .astype("string")
                .str.strip()
                .str.lower()
            )

    return result


def standardize_dates(df: pd.DataFrame) -> pd.DataFrame:
    """Convert known date fields to consistent datetime values."""
    result = df.copy()

    date_columns = [
        "order_date",
        "payment_date",
        "cancelled_date",
        "last_order_date",
    ]

    for column in date_columns:
        if column in result.columns:
            result[column] = pd.to_datetime(
                result[column], errors="coerce"
            )

    return result
