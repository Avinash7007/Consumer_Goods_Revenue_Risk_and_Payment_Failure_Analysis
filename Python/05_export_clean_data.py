"""
Customer Churn & Revenue Risk Analysis
---------------------------------------
File: 05_export_clean_data.py

Purpose:
    Load validated, cleaned datasets from Pandas into
    SQL Server staging tables.

Pipeline:
    Raw Data
        ↓
    Python Cleaning
        ↓
    Python Validation
        ↓
    SQL Server Staging Tables

Technology:
    Python
    Pandas
    SQL Server
    SQLAlchemy
    pyodbc
"""

from pathlib import Path
import os

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine


# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

CLEAN_DATA_DIR = BASE_DIR / "data" / "clean"


# ============================================================
# DATABASE CONFIGURATION
# ============================================================

# IMPORTANT:
# Do not hard-code credentials in this file.
#
# Recommended production setup:
#
# Windows environment variables:
#
# SQL_SERVER
# SQL_DATABASE
# SQL_DRIVER
#
# Example:
#
# SQL_SERVER=YOUR_SERVER
# SQL_DATABASE=YOUR_DATABASE
# SQL_DRIVER=ODBC Driver 17 for SQL Server


SQL_SERVER = os.getenv(
    "SQL_SERVER",
    "YOUR_SERVER"
)

SQL_DATABASE = os.getenv(
    "SQL_DATABASE",
    "YOUR_DATABASE"
)

SQL_DRIVER = os.getenv(
    "SQL_DRIVER",
    "ODBC Driver 17 for SQL Server"
)


# ============================================================
# SOURCE FILES
# ============================================================

CUSTOMER_FILE = (
    CLEAN_DATA_DIR /
    "customers_clean.csv"
)

ORDER_FILE = (
    CLEAN_DATA_DIR /
    "orders_clean.csv"
)

PAYMENT_FILE = (
    CLEAN_DATA_DIR /
    "payments_clean.csv"
)


# ============================================================
# SQL TABLE NAMES
# ============================================================

CUSTOMER_TABLE = "stg_customers"

ORDER_TABLE = "stg_orders"

PAYMENT_TABLE = "stg_payments"


# ============================================================
# SQL SERVER CONNECTION
# ============================================================

def create_sql_engine() -> Engine:
    """
    Create SQL Server SQLAlchemy engine.

    Uses Windows Authentication by default.
    """

    if (
        SQL_SERVER == "YOUR_SERVER"
        or SQL_DATABASE == "YOUR_DATABASE"
    ):

        raise ValueError(
            "SQL Server configuration is missing. "
            "Set SQL_SERVER and SQL_DATABASE "
            "environment variables."
        )

    connection_string = (
        f"mssql+pyodbc://@"
        f"{SQL_SERVER}/"
        f"{SQL_DATABASE}"
        f"?driver="
        f"{SQL_DRIVER.replace(' ', '+')}"
        "&trusted_connection=yes"
    )

    engine = create_engine(
        connection_string,
        fast_executemany=True
    )

    return engine


# ============================================================
# DATA LOADING
# ============================================================

def load_clean_csv(
    file_path: Path,
    dataset_name: str
) -> pd.DataFrame:
    """
    Load cleaned CSV into Pandas.
    """

    if not file_path.exists():

        raise FileNotFoundError(
            f"{dataset_name} file not found: "
            f"{file_path}"
        )

    df = pd.read_csv(
        file_path
    )

    print(
        f"{dataset_name} loaded: "
        f"{len(df):,} rows"
    )

    return df


# ============================================================
# PRE-LOAD VALIDATION
# ============================================================

def validate_before_load(
    df: pd.DataFrame,
    required_columns: list[str],
    dataset_name: str
) -> None:
    """
    Perform basic checks before sending data to SQL Server.
    """

    # --------------------------------------------------------
    # Required columns
    # --------------------------------------------------------

    missing_columns = [
        column
        for column in required_columns
        if column not in df.columns
    ]

    if missing_columns:

        raise ValueError(
            f"{dataset_name} is missing required "
            f"columns: {missing_columns}"
        )

    # --------------------------------------------------------
    # Empty dataset
    # --------------------------------------------------------

    if df.empty:

        raise ValueError(
            f"{dataset_name} contains zero rows."
        )

    # --------------------------------------------------------
    # Duplicate rows
    # --------------------------------------------------------

    duplicate_rows = (
        df.duplicated().sum()
    )

    if duplicate_rows > 0:

        raise ValueError(
            f"{dataset_name} contains "
            f"{duplicate_rows:,} duplicate rows."
        )

    print(
        f"Pre-load validation passed: "
        f"{dataset_name}"
    )


# ============================================================
# SQL SERVER LOAD
# ============================================================

def load_to_sql(
    df: pd.DataFrame,
    engine: Engine,
    table_name: str,
    dataset_name: str
) -> None:
    """
    Load DataFrame into SQL Server staging table.

    if_exists='replace' is intentional for this staging layer.
    Production persistent tables should be managed through
    controlled SQL deployment/migration scripts.
    """

    print(
        f"\nLoading {dataset_name} "
        f"into dbo.{table_name}..."
    )

    df.to_sql(
        name=table_name,
        con=engine,
        schema="dbo",
        if_exists="replace",
        index=False,
        chunksize=5_000,
        method=None
    )

    print(
        f"Loaded {len(df):,} rows "
        f"into dbo.{table_name}"
    )


# ============================================================
# SQL ROW COUNT VALIDATION
# ============================================================

def validate_sql_row_count(
    engine: Engine,
    table_name: str,
    expected_count: int,
    dataset_name: str
) -> None:
    """
    Verify that SQL Server contains the expected
    number of loaded rows.
    """

    query = f"""
        SELECT COUNT(*) AS row_count
        FROM dbo.{table_name};
    """

    result = pd.read_sql(
        query,
        engine
    )

    sql_count = int(
        result.loc[0, "row_count"]
    )

    if sql_count != expected_count:

        raise RuntimeError(
            f"{dataset_name} row-count mismatch. "
            f"Expected {expected_count:,}, "
            f"loaded {sql_count:,}."
        )

    print(
        f"PASS - {dataset_name}: "
        f"{sql_count:,} rows verified in SQL Server."
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 80)
    print("CUSTOMER CHURN & REVENUE RISK ANALYSIS")
    print("CLEAN DATA → SQL SERVER STAGING")
    print("=" * 80)

    # ========================================================
    # LOAD CLEAN DATA
    # ========================================================

    customers = load_clean_csv(
        CUSTOMER_FILE,
        "Customers"
    )

    orders = load_clean_csv(
        ORDER_FILE,
        "Orders"
    )

    payments = load_clean_csv(
        PAYMENT_FILE,
        "Payments"
    )

    # ========================================================
    # PRE-LOAD VALIDATION
    # ========================================================

    validate_before_load(
        customers,
        ["customer_id"],
        "Customers"
    )

    validate_before_load(
        orders,
        ["order_id", "customer_id"],
        "Orders"
    )

    validate_before_load(
        payments,
        ["payment_id", "order_id"],
        "Payments"
    )

    # ========================================================
    # CREATE DATABASE ENGINE
    # ========================================================

    engine = create_sql_engine()

    # ========================================================
    # LOAD STAGING TABLES
    # ========================================================

    load_to_sql(
        customers,
        engine,
        CUSTOMER_TABLE,
        "Customers"
    )

    load_to_sql(
        orders,
        engine,
        ORDER_TABLE,
        "Orders"
    )

    load_to_sql(
        payments,
        engine,
        PAYMENT_TABLE,
        "Payments"
    )

    # ========================================================
    # SQL ROW COUNT VALIDATION
    # ========================================================

    validate_sql_row_count(
        engine,
        CUSTOMER_TABLE,
        len(customers),
        "Customers"
    )

    validate_sql_row_count(
        engine,
        ORDER_TABLE,
        len(orders),
        "Orders"
    )

    validate_sql_row_count(
        engine,
        PAYMENT_TABLE,
        len(payments),
        "Payments"
    )

    # ========================================================
    # COMPLETION
    # ========================================================

    print("\n" + "=" * 80)
    print("SQL SERVER LOAD COMPLETED SUCCESSFULLY")
    print("=" * 80)

    print(
        "\nStaging tables created:"
    )

    print(
        "dbo.stg_customers"
    )

    print(
        "dbo.stg_orders"
    )

    print(
        "dbo.stg_payments"
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()