"""
Customer Churn & Revenue Risk Analysis
---------------------------------------
File: 01_load_data.py

Purpose:
    Load raw customer/order/payment data from multiple sources
    and perform basic structural inspection.

Technology:
    Python
    Pandas
    SQL Server

Project:
    Consumer Goods - Customer Churn & Revenue Risk Analysis

Important:
    This script does NOT perform business analysis.
    Cleaning and validation are handled in separate modules.
"""

from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine


# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DATA_DIR = BASE_DIR / "data" / "raw"

CUSTOMER_FILE = RAW_DATA_DIR / "customers.csv"
ORDER_FILE = RAW_DATA_DIR / "orders.csv"
PAYMENT_FILE = RAW_DATA_DIR / "payments.csv"


# ============================================================
# DATABASE CONFIGURATION
# ============================================================

# Keep credentials outside the source code in production.
# Example:
#
# SQL_SERVER = "SERVER_NAME"
# SQL_DATABASE = "DATABASE_NAME"
#
# Use environment variables / secrets management instead
# of hard-coding username and password.

SQL_SERVER = "YOUR_SERVER"
SQL_DATABASE = "YOUR_DATABASE"
SQL_DRIVER = "ODBC Driver 17 for SQL Server"


def create_sql_connection():
    """
    Create SQL Server connection.

    Credentials should be supplied through a secure
    environment/configuration mechanism in production.
    """

    connection_string = (
        f"mssql+pyodbc://@{SQL_SERVER}/{SQL_DATABASE}"
        f"?driver={SQL_DRIVER.replace(' ', '+')}"
        "&trusted_connection=yes"
    )

    return create_engine(connection_string)


# ============================================================
# CSV / EXCEL LOADERS
# ============================================================

def load_csv(file_path: Path) -> pd.DataFrame:
    """
    Load a CSV file into a Pandas DataFrame.
    """

    if not file_path.exists():
        raise FileNotFoundError(
            f"Source file not found: {file_path}"
        )

    df = pd.read_csv(file_path)

    print(f"Loaded: {file_path.name}")
    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns):,}")
    print("-" * 60)

    return df


def load_excel(file_path: Path, sheet_name=0) -> pd.DataFrame:
    """
    Load an Excel worksheet into a Pandas DataFrame.
    """

    if not file_path.exists():
        raise FileNotFoundError(
            f"Source file not found: {file_path}"
        )

    df = pd.read_excel(
        file_path,
        sheet_name=sheet_name
    )

    print(f"Loaded: {file_path.name}")
    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns):,}")
    print("-" * 60)

    return df


# ============================================================
# DATA PROFILE
# ============================================================

def profile_dataframe(df: pd.DataFrame, name: str) -> None:
    """
    Perform basic structural profiling.

    This function does NOT clean or modify the DataFrame.
    """

    print(f"\n{'=' * 60}")
    print(f"DATA PROFILE: {name}")
    print(f"{'=' * 60}")

    print(f"Rows          : {len(df):,}")
    print(f"Columns       : {len(df.columns):,}")
    print(f"Duplicate Rows: {df.duplicated().sum():,}")

    print("\nColumn Data Types:")
    print(df.dtypes)

    print("\nMissing Values:")
    missing = df.isna().sum()

    missing = missing[missing > 0]

    if missing.empty:
        print("No missing values detected.")
    else:
        print(missing.sort_values(ascending=False))


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 60)
    print("CUSTOMER CHURN & REVENUE RISK ANALYSIS")
    print("RAW DATA INGESTION")
    print("=" * 60)

    # --------------------------------------------------------
    # 1. Load Customers
    # --------------------------------------------------------

    if CUSTOMER_FILE.exists():

        customers_df = load_csv(CUSTOMER_FILE)

        profile_dataframe(
            customers_df,
            "Customers"
        )

    else:
        print(
            f"\nCustomer file not found: {CUSTOMER_FILE}"
        )

    # --------------------------------------------------------
    # 2. Load Orders
    # --------------------------------------------------------

    if ORDER_FILE.exists():

        orders_df = load_csv(ORDER_FILE)

        profile_dataframe(
            orders_df,
            "Orders"
        )

    else:
        print(
            f"\nOrder file not found: {ORDER_FILE}"
        )

    # --------------------------------------------------------
    # 3. Load Payments
    # --------------------------------------------------------

    if PAYMENT_FILE.exists():

        payments_df = load_csv(PAYMENT_FILE)

        profile_dataframe(
            payments_df,
            "Payments"
        )

    else:
        print(
            f"\nPayment file not found: {PAYMENT_FILE}"
        )

    print("\n" + "=" * 60)
    print("RAW DATA INGESTION COMPLETED")
    print("=" * 60)


if __name__ == "__main__":
    main()