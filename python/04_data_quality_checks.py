"""
Customer Churn & Revenue Risk Analysis
Python / Pandas - Data Quality Checks
"""

import pandas as pd


def profile_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """Return a compact data-quality profile for every column."""
    return pd.DataFrame(
        {
            "dtype": df.dtypes.astype(str),
            "null_count": df.isna().sum(),
            "null_pct": (df.isna().mean() * 100).round(2),
            "unique_count": df.nunique(dropna=True),
        }
    ).sort_values("null_pct", ascending=False)


def check_duplicate_rows(df: pd.DataFrame) -> int:
    """Return the number of duplicate rows."""
    return int(df.duplicated().sum())


def check_required_columns(df: pd.DataFrame, required: list[str]) -> list[str]:
    """Return required columns that are missing from the dataframe."""
    return [column for column in required if column not in df.columns]


def run_quality_checks(df: pd.DataFrame) -> None:
    """Print production-oriented quality checks."""
    print("Rows:", len(df))
    print("Columns:", len(df.columns))
    print("Duplicate rows:", check_duplicate_rows(df))
    print("Missing required columns:", check_required_columns(
        df,
        ["order_id", "customer_id", "order_date"],
    ))
    print("\nColumn profile:")
    print(profile_dataframe(df))
