"""
Customer Churn & Revenue Risk Analysis
---------------------------------------
File: 02_profile_data.py

Purpose:
    Profile raw datasets before cleaning.

Checks:
    - Dataset shape
    - Column names
    - Data types
    - Missing values
    - Duplicate records
    - Unique values
    - Date ranges
    - Numeric ranges
    - Categorical distributions

Technology:
    Python
    Pandas
"""

from pathlib import Path
import pandas as pd


# ============================================================
# CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DATA_DIR = BASE_DIR / "data" / "raw"

CUSTOMER_FILE = RAW_DATA_DIR / "customers.csv"
ORDER_FILE = RAW_DATA_DIR / "orders.csv"
PAYMENT_FILE = RAW_DATA_DIR / "payments.csv"


# ============================================================
# GENERAL DATASET PROFILE
# ============================================================

def profile_dataset(df: pd.DataFrame, dataset_name: str) -> None:
    """
    Generate a complete structural profile of a dataset.

    This function does not modify the original DataFrame.
    """

    print("\n" + "=" * 80)
    print(f"DATASET PROFILE: {dataset_name}")
    print("=" * 80)

    # --------------------------------------------------------
    # Basic information
    # --------------------------------------------------------

    print("\n[1] DATASET SIZE")

    print(f"Rows    : {df.shape[0]:,}")
    print(f"Columns : {df.shape[1]:,}")

    # --------------------------------------------------------
    # Column names
    # --------------------------------------------------------

    print("\n[2] COLUMN NAMES")

    for column in df.columns:
        print(f"- {column}")

    # --------------------------------------------------------
    # Data types
    # --------------------------------------------------------

    print("\n[3] DATA TYPES")

    dtype_profile = pd.DataFrame({
        "Column": df.columns,
        "DataType": df.dtypes.astype(str).values
    })

    print(
        dtype_profile.to_string(index=False)
    )

    # --------------------------------------------------------
    # Missing values
    # --------------------------------------------------------

    print("\n[4] MISSING VALUES")

    missing = pd.DataFrame({
        "Column": df.columns,
        "MissingCount": df.isna().sum().values,
        "MissingPercentage": (
            df.isna().mean().values * 100
        )
    })

    missing = missing[
        missing["MissingCount"] > 0
    ].sort_values(
        by="MissingPercentage",
        ascending=False
    )

    if missing.empty:
        print("No missing values detected.")

    else:
        print(
            missing.to_string(index=False)
        )

    # --------------------------------------------------------
    # Duplicate rows
    # --------------------------------------------------------

    print("\n[5] DUPLICATE RECORDS")

    duplicate_count = df.duplicated().sum()

    print(
        f"Duplicate Rows: {duplicate_count:,}"
    )

    # --------------------------------------------------------
    # Unique values
    # --------------------------------------------------------

    print("\n[6] UNIQUE VALUE COUNTS")

    unique_profile = pd.DataFrame({
        "Column": df.columns,
        "UniqueValues": [
            df[column].nunique(dropna=True)
            for column in df.columns
        ]
    })

    print(
        unique_profile.to_string(index=False)
    )

    # --------------------------------------------------------
    # Numeric columns
    # --------------------------------------------------------

    numeric_columns = df.select_dtypes(
        include="number"
    ).columns

    if len(numeric_columns) > 0:

        print("\n[7] NUMERIC COLUMN PROFILE")

        numeric_profile = df[
            numeric_columns
        ].describe().T

        print(
            numeric_profile.to_string()
        )

    # --------------------------------------------------------
    # Categorical columns
    # --------------------------------------------------------

    categorical_columns = df.select_dtypes(
        include=["object", "category"]
    ).columns

    if len(categorical_columns) > 0:

        print("\n[8] CATEGORICAL COLUMN PROFILE")

        for column in categorical_columns:

            print(f"\n--- {column} ---")

            value_counts = (
                df[column]
                .value_counts(dropna=False)
                .head(20)
            )

            print(
                value_counts.to_string()
            )

    print("\n" + "-" * 80)


# ============================================================
# DATE COLUMN PROFILING
# ============================================================

def profile_date_column(
    df: pd.DataFrame,
    column_name: str,
    dataset_name: str
) -> None:
    """
    Profile a date column without modifying the source DataFrame.
    """

    if column_name not in df.columns:
        return

    print(
        f"\n[DATE PROFILE] "
        f"{dataset_name} → {column_name}"
    )

    converted_dates = pd.to_datetime(
        df[column_name],
        errors="coerce"
    )

    valid_dates = converted_dates.dropna()

    if valid_dates.empty:
        print("No valid dates detected.")
        return

    print(
        f"Minimum Date: {valid_dates.min()}"
    )

    print(
        f"Maximum Date: {valid_dates.max()}"
    )

    print(
        f"Invalid Dates: "
        f"{converted_dates.isna().sum():,}"
    )


# ============================================================
# DATASET LOADER
# ============================================================

def load_dataset(
    file_path: Path,
    dataset_name: str
) -> pd.DataFrame | None:
    """
    Load CSV safely and return DataFrame.
    """

    if not file_path.exists():

        print(
            f"\nWARNING: {dataset_name} file not found:"
        )

        print(file_path)

        return None

    try:

        df = pd.read_csv(
            file_path
        )

        print(
            f"\nLoaded {dataset_name}: "
            f"{len(df):,} rows"
        )

        return df

    except Exception as error:

        print(
            f"\nERROR loading {dataset_name}: "
            f"{error}"
        )

        return None


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 80)
    print("CUSTOMER CHURN & REVENUE RISK ANALYSIS")
    print("RAW DATA QUALITY PROFILING")
    print("=" * 80)

    # ========================================================
    # CUSTOMERS
    # ========================================================

    customers_df = load_dataset(
        CUSTOMER_FILE,
        "Customers"
    )

    if customers_df is not None:

        profile_dataset(
            customers_df,
            "Customers"
        )

        # Try common customer date fields
        for column in [
            "RegistrationDate",
            "SignupDate",
            "CustomerSince"
        ]:

            profile_date_column(
                customers_df,
                column,
                "Customers"
            )

    # ========================================================
    # ORDERS
    # ========================================================

    orders_df = load_dataset(
        ORDER_FILE,
        "Orders"
    )

    if orders_df is not None:

        profile_dataset(
            orders_df,
            "Orders"
        )

        # Profile common order dates
        for column in [
            "OrderDate",
            "Order_Date",
            "CreatedDate"
        ]:

            profile_date_column(
                orders_df,
                column,
                "Orders"
            )

    # ========================================================
    # PAYMENTS
    # ========================================================

    payments_df = load_dataset(
        PAYMENT_FILE,
        "Payments"
    )

    if payments_df is not None:

        profile_dataset(
            payments_df,
            "Payments"
        )

        # Profile common payment dates
        for column in [
            "PaymentDate",
            "Payment_Date",
            "TransactionDate"
        ]:

            profile_date_column(
                payments_df,
                column,
                "Payments"
            )

    # ========================================================
    # COMPLETION
    # ========================================================

    print("\n" + "=" * 80)
    print("DATA PROFILING COMPLETED")
    print("=" * 80)

    print(
        "\nNo source data was modified."
    )

    print(
        "Use the profiling output to define "
        "the cleaning rules in 03_clean_data.py."
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()