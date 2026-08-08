"""
Customer Churn & Revenue Risk Analysis
---------------------------------------
File: 03_clean_data.py

Purpose:
    Clean and standardize raw customer, order and payment data
    before SQL analysis.

Cleaning operations:
    - Column-name standardization
    - Duplicate removal
    - Missing-value handling
    - Data-type conversion
    - Date standardization
    - Text standardization
    - Status/category standardization
    - Numeric validation
    - Business-rule checks

Technology:
    Python
    Pandas
"""

from pathlib import Path
import re
import pandas as pd


# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DATA_DIR = BASE_DIR / "data" / "raw"
CLEAN_DATA_DIR = BASE_DIR / "data" / "clean"

CLEAN_DATA_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# FILE PATHS
# ============================================================

CUSTOMER_FILE = RAW_DATA_DIR / "customers.csv"
ORDER_FILE = RAW_DATA_DIR / "orders.csv"
PAYMENT_FILE = RAW_DATA_DIR / "payments.csv"


# ============================================================
# COMMON CLEANING FUNCTIONS
# ============================================================

def standardize_column_names(df: pd.DataFrame) -> pd.DataFrame:
    """
    Standardize column names to snake_case.
    """

    df = df.copy()

    def clean_name(column):
        column = str(column).strip()
        column = re.sub(
            r"[^a-zA-Z0-9]+",
            "_",
            column
        )
        column = re.sub(
            r"_+",
            "_",
            column
        )
        return column.strip("_").lower()

    df.columns = [
        clean_name(column)
        for column in df.columns
    ]

    return df


def clean_text_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Remove unnecessary whitespace and normalize text fields.
    """

    df = df.copy()

    text_columns = df.select_dtypes(
        include=["object", "string"]
    ).columns

    for column in text_columns:

        df[column] = (
            df[column]
            .astype("string")
            .str.strip()
        )

        # Convert blank strings to missing values
        df[column] = df[column].replace(
            {
                "": pd.NA,
                "nan": pd.NA,
                "None": pd.NA,
                "NULL": pd.NA,
                "null": pd.NA
            }
        )

    return df


def remove_duplicates(
    df: pd.DataFrame,
    dataset_name: str
) -> pd.DataFrame:
    """
    Remove exact duplicate rows.
    """

    df = df.copy()

    before = len(df)

    df = df.drop_duplicates()

    removed = before - len(df)

    print(
        f"{dataset_name}: "
        f"{removed:,} duplicate rows removed."
    )

    return df


# ============================================================
# DATE CLEANING
# ============================================================

def standardize_dates(
    df: pd.DataFrame,
    date_columns: list[str]
) -> pd.DataFrame:
    """
    Convert known date columns to datetime.
    """

    df = df.copy()

    for column in date_columns:

        if column not in df.columns:
            continue

        df[column] = pd.to_datetime(
            df[column],
            errors="coerce"
        )

    return df


# ============================================================
# NUMERIC CLEANING
# ============================================================

def standardize_numeric_columns(
    df: pd.DataFrame,
    numeric_columns: list[str]
) -> pd.DataFrame:
    """
    Convert numeric fields safely using coercion.
    """

    df = df.copy()

    for column in numeric_columns:

        if column not in df.columns:
            continue

        df[column] = pd.to_numeric(
            df[column],
            errors="coerce"
        )

    return df


# ============================================================
# STATUS STANDARDIZATION
# ============================================================

def standardize_status_column(
    df: pd.DataFrame,
    column_name: str
) -> pd.DataFrame:
    """
    Normalize status values.

    Example:
        cancelled
        CANCELED
        Cancelled
        cancelled order

    are standardized where possible.
    """

    df = df.copy()

    if column_name not in df.columns:
        return df

    df[column_name] = (
        df[column_name]
        .astype("string")
        .str.strip()
        .str.lower()
    )

    status_mapping = {
        "canceled": "cancelled",
        "cancel": "cancelled",
        "cancelled order": "cancelled",
        "complete": "completed",
        "completed order": "completed",
        "success": "successful",
        "successful payment": "successful",
        "failed payment": "failed",
        "failure": "failed"
    }

    df[column_name] = (
        df[column_name]
        .replace(status_mapping)
    )

    return df


# ============================================================
# MISSING VALUE HANDLING
# ============================================================

def handle_missing_values(
    df: pd.DataFrame,
    dataset_name: str
) -> pd.DataFrame:
    """
    Handle missing values conservatively.

    Important:
        Do NOT blindly fill all missing values.
        Missing identifiers are removed because they cannot
        reliably participate in joins.

        Numeric/business fields remain missing unless a
        business rule explicitly defines a safe replacement.
    """

    df = df.copy()

    print(
        f"\nMissing-value handling: {dataset_name}"
    )

    # Identify likely identifier columns
    identifier_columns = [
        column
        for column in df.columns
        if column.endswith("_id")
        or column in {
            "customer_id",
            "order_id",
            "payment_id"
        }
    ]

    for column in identifier_columns:

        if column not in df.columns:
            continue

        before = len(df)

        df = df.dropna(
            subset=[column]
        )

        removed = before - len(df)

        if removed > 0:
            print(
                f"{column}: "
                f"{removed:,} rows removed due to missing ID."
            )

    return df


# ============================================================
# CUSTOMER CLEANING
# ============================================================

def clean_customers(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean customer master data.
    """

    print("\nCleaning Customers...")

    df = standardize_column_names(df)

    df = clean_text_columns(df)

    df = remove_duplicates(
        df,
        "Customers"
    )

    df = handle_missing_values(
        df,
        "Customers"
    )

    # Standardize common customer date fields
    df = standardize_dates(
        df,
        [
            "registration_date",
            "signup_date",
            "customer_since"
        ]
    )

    # Standardize common customer attributes
    for column in [
        "gender",
        "segment",
        "customer_type",
        "status"
    ]:

        if column in df.columns:

            df[column] = (
                df[column]
                .astype("string")
                .str.strip()
            )

    return df


# ============================================================
# ORDER CLEANING
# ============================================================

def clean_orders(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean transactional order data.
    """

    print("\nCleaning Orders...")

    df = standardize_column_names(df)

    df = clean_text_columns(df)

    df = remove_duplicates(
        df,
        "Orders"
    )

    df = handle_missing_values(
        df,
        "Orders"
    )

    # Date standardization
    df = standardize_dates(
        df,
        [
            "order_date",
            "orderdate",
            "cancel_date",
            "cancellation_date",
            "ship_date"
        ]
    )

    # Numeric fields
    df = standardize_numeric_columns(
        df,
        [
            "quantity",
            "sales",
            "revenue",
            "amount",
            "discount"
        ]
    )

    # Order status
    for column in [
        "order_status",
        "status",
        "payment_status"
    ]:

        df = standardize_status_column(
            df,
            column
        )

    # --------------------------------------------------------
    # Business-rule checks
    # --------------------------------------------------------

    if "quantity" in df.columns:

        invalid_quantity = (
            df["quantity"] < 0
        ).sum()

        print(
            f"Invalid quantity rows: "
            f"{invalid_quantity:,}"
        )

    if "discount" in df.columns:

        invalid_discount = (
            (df["discount"] < 0)
            |
            (df["discount"] > 1)
        ).sum()

        print(
            f"Invalid discount rows: "
            f"{invalid_discount:,}"
        )

    return df


# ============================================================
# PAYMENT CLEANING
# ============================================================

def clean_payments(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean payment transaction data.
    """

    print("\nCleaning Payments...")

    df = standardize_column_names(df)

    df = clean_text_columns(df)

    df = remove_duplicates(
        df,
        "Payments"
    )

    df = handle_missing_values(
        df,
        "Payments"
    )

    # Date fields
    df = standardize_dates(
        df,
        [
            "payment_date",
            "paymentdate",
            "transaction_date"
        ]
    )

    # Monetary fields
    df = standardize_numeric_columns(
        df,
        [
            "amount",
            "payment_amount",
            "revenue",
            "refund_amount"
        ]
    )

    # Payment status
    for column in [
        "payment_status",
        "status",
        "transaction_status"
    ]:

        df = standardize_status_column(
            df,
            column
        )

    return df


# ============================================================
# SAVE CLEAN DATA
# ============================================================

def save_clean_data(
    df: pd.DataFrame,
    file_name: str
) -> None:
    """
    Save cleaned DataFrame as CSV.
    """

    output_path = (
        CLEAN_DATA_DIR / file_name
    )

    df.to_csv(
        output_path,
        index=False
    )

    print(
        f"Saved: {output_path}"
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 80)
    print("CUSTOMER CHURN & REVENUE RISK ANALYSIS")
    print("DATA CLEANING PIPELINE")
    print("=" * 80)

    # ========================================================
    # CUSTOMERS
    # ========================================================

    if CUSTOMER_FILE.exists():

        customers = pd.read_csv(
            CUSTOMER_FILE
        )

        customers_clean = clean_customers(
            customers
        )

        save_clean_data(
            customers_clean,
            "customers_clean.csv"
        )

    else:

        print(
            f"Customer file not found: "
            f"{CUSTOMER_FILE}"
        )

    # ========================================================
    # ORDERS
    # ========================================================

    if ORDER_FILE.exists():

        orders = pd.read_csv(
            ORDER_FILE
        )

        orders_clean = clean_orders(
            orders
        )

        save_clean_data(
            orders_clean,
            "orders_clean.csv"
        )

    else:

        print(
            f"Order file not found: "
            f"{ORDER_FILE}"
        )

    # ========================================================
    # PAYMENTS
    # ========================================================

    if PAYMENT_FILE.exists():

        payments = pd.read_csv(
            PAYMENT_FILE
        )

        payments_clean = clean_payments(
            payments
        )

        save_clean_data(
            payments_clean,
            "payments_clean.csv"
        )

    else:

        print(
            f"Payment file not found: "
            f"{PAYMENT_FILE}"
        )

    print("\n" + "=" * 80)
    print("DATA CLEANING COMPLETED")
    print("=" * 80)

    print(
        "\nClean datasets are available in:"
    )

    print(CLEAN_DATA_DIR)


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()