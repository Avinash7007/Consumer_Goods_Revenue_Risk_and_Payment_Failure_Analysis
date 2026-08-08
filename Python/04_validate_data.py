"""
Customer Churn & Revenue Risk Analysis
---------------------------------------
File: 04_validate_data.py

Purpose:
    Validate cleaned customer, order and payment datasets
    before loading them into SQL Server / performing analysis.

Validation areas:
    - File availability
    - Row counts
    - Required columns
    - Duplicate primary keys
    - Missing key fields
    - Date validity
    - Customer-to-order integrity
    - Order-to-payment integrity
    - Cancellation metrics
    - Revenue loss
    - Customer inactivity
    - Data-quality summary

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

CLEAN_DATA_DIR = BASE_DIR / "data" / "clean"

CUSTOMER_FILE = CLEAN_DATA_DIR / "customers_clean.csv"
ORDER_FILE = CLEAN_DATA_DIR / "orders_clean.csv"
PAYMENT_FILE = CLEAN_DATA_DIR / "payments_clean.csv"


# ============================================================
# PROJECT BUSINESS TARGETS
# ============================================================

EXPECTED_TOTAL_ORDERS = 40_000
EXPECTED_CANCELLED_ORDERS = 13_381
EXPECTED_CANCELLATION_RATE = 33.45

EXPECTED_REVENUE_LOSS = 2_500_000
EXPECTED_AT_RISK_CUSTOMERS = 2_389

CHURN_DAYS = 90


# ============================================================
# HELPERS
# ============================================================

def load_clean_data(
    file_path: Path,
    dataset_name: str
) -> pd.DataFrame:
    """
    Load a cleaned CSV dataset.
    """

    if not file_path.exists():
        raise FileNotFoundError(
            f"{dataset_name} file not found: {file_path}"
        )

    df = pd.read_csv(file_path)

    print(
        f"{dataset_name}: "
        f"{len(df):,} rows loaded."
    )

    return df


def find_column(
    df: pd.DataFrame,
    candidates: list[str]
) -> str | None:
    """
    Return the first matching column from a list of candidates.
    """

    for column in candidates:

        if column in df.columns:
            return column

    return None


def check_required_columns(
    df: pd.DataFrame,
    required_columns: list[str],
    dataset_name: str
) -> bool:
    """
    Check whether required columns exist.
    """

    missing_columns = [
        column
        for column in required_columns
        if column not in df.columns
    ]

    if missing_columns:

        print(
            f"FAIL - {dataset_name} missing columns:"
        )

        for column in missing_columns:
            print(f"  - {column}")

        return False

    print(
        f"PASS - {dataset_name} required columns available."
    )

    return True


# ============================================================
# DUPLICATE KEY VALIDATION
# ============================================================

def validate_unique_key(
    df: pd.DataFrame,
    column: str | None,
    dataset_name: str
) -> bool:
    """
    Validate uniqueness of a primary/business key.
    """

    if column is None:

        print(
            f"SKIP - No key column identified for {dataset_name}."
        )

        return True

    duplicate_count = (
        df[column]
        .duplicated()
        .sum()
    )

    if duplicate_count > 0:

        print(
            f"FAIL - {dataset_name}: "
            f"{duplicate_count:,} duplicate {column} values."
        )

        return False

    print(
        f"PASS - {dataset_name}: "
        f"{column} is unique."
    )

    return True


# ============================================================
# MISSING KEY VALIDATION
# ============================================================

def validate_missing_keys(
    df: pd.DataFrame,
    key_columns: list[str],
    dataset_name: str
) -> bool:
    """
    Check missing values in critical identifiers.
    """

    failed = False

    for column in key_columns:

        if column not in df.columns:
            continue

        missing_count = df[column].isna().sum()

        if missing_count > 0:

            print(
                f"FAIL - {dataset_name}.{column}: "
                f"{missing_count:,} missing values."
            )

            failed = True

        else:

            print(
                f"PASS - {dataset_name}.{column}: "
                f"no missing values."
            )

    return not failed


# ============================================================
# DATE VALIDATION
# ============================================================

def validate_dates(
    df: pd.DataFrame,
    date_columns: list[str],
    dataset_name: str
) -> bool:
    """
    Validate date conversion and invalid date records.
    """

    failed = False

    for column in date_columns:

        if column not in df.columns:
            continue

        converted = pd.to_datetime(
            df[column],
            errors="coerce"
        )

        invalid_count = converted.isna().sum()

        if invalid_count > 0:

            print(
                f"WARNING - {dataset_name}.{column}: "
                f"{invalid_count:,} invalid/missing dates."
            )

        else:

            print(
                f"PASS - {dataset_name}.{column}: "
                f"valid dates."
            )

    return not failed


# ============================================================
# ORDER VALIDATION
# ============================================================

def validate_orders(
    orders: pd.DataFrame
) -> dict:
    """
    Validate order-level business metrics.
    """

    print("\n" + "=" * 70)
    print("ORDER BUSINESS VALIDATION")
    print("=" * 70)

    order_id = find_column(
        orders,
        [
            "order_id",
            "orderid"
        ]
    )

    status = find_column(
        orders,
        [
            "order_status",
            "status"
        ]
    )

    revenue = find_column(
        orders,
        [
            "revenue",
            "sales",
            "amount"
        ]
    )

    if order_id is None:

        raise ValueError(
            "Order ID column could not be identified."
        )

    total_orders = (
        orders[order_id]
        .nunique()
    )

    print(
        f"Total Orders: {total_orders:,}"
    )

    # --------------------------------------------------------
    # Cancellation analysis
    # --------------------------------------------------------

    cancelled_orders = None
    cancellation_rate = None

    if status is not None:

        normalized_status = (
            orders[status]
            .astype("string")
            .str.strip()
            .str.lower()
        )

        cancelled_mask = (
            normalized_status == "cancelled"
        )

        cancelled_orders = (
            orders.loc[
                cancelled_mask,
                order_id
            ]
            .nunique()
        )

        cancellation_rate = (
            cancelled_orders
            / total_orders
            * 100
        )

        print(
            f"Cancelled Orders: "
            f"{cancelled_orders:,}"
        )

        print(
            f"Cancellation Rate: "
            f"{cancellation_rate:.2f}%"
        )

    # --------------------------------------------------------
    # Revenue loss
    # --------------------------------------------------------

    revenue_loss = None

    if revenue is not None and status is not None:

        revenue_values = pd.to_numeric(
            orders[revenue],
            errors="coerce"
        ).fillna(0)

        revenue_loss = revenue_values[
            cancelled_mask
        ].sum()

        print(
            f"Calculated Cancelled-Order Revenue: "
            f"₹{revenue_loss:,.2f}"
        )

    return {
        "total_orders": total_orders,
        "cancelled_orders": cancelled_orders,
        "cancellation_rate": cancellation_rate,
        "revenue_loss": revenue_loss
    }


# ============================================================
# CHANNEL VALIDATION
# ============================================================

def validate_channel_cancellations(
    orders: pd.DataFrame
) -> None:
    """
    Validate cancellation behaviour by order channel.
    """

    channel = find_column(
        orders,
        [
            "order_channel",
            "channel",
            "sales_channel"
        ]
    )

    status = find_column(
        orders,
        [
            "order_status",
            "status"
        ]
    )

    if channel is None or status is None:
        print(
            "\nSKIP - Channel cancellation analysis "
            "columns not available."
        )
        return

    order_id = find_column(
        orders,
        [
            "order_id",
            "orderid"
        ]
    )

    normalized_status = (
        orders[status]
        .astype("string")
        .str.strip()
        .str.lower()
    )

    cancelled = (
        normalized_status == "cancelled"
    )

    channel_summary = (
        orders
        .groupby(channel)
        .agg(
            TotalOrders=(
                order_id,
                "nunique"
            )
        )
    )

    cancelled_summary = (
        orders.loc[cancelled]
        .groupby(channel)
        .agg(
            CancelledOrders=(
                order_id,
                "nunique"
            )
        )
    )

    result = (
        channel_summary
        .join(
            cancelled_summary,
            how="left"
        )
        .fillna(0)
    )

    result["CancellationRate"] = (
        result["CancelledOrders"]
        / result["TotalOrders"]
        * 100
    )

    print("\nCancellation by Channel:")
    print(
        result.to_string()
    )


# ============================================================
# CUSTOMER-ORDER INTEGRITY
# ============================================================

def validate_customer_order_relationship(
    customers: pd.DataFrame,
    orders: pd.DataFrame
) -> None:
    """
    Check whether order customer IDs exist in customer master.
    """

    customer_id_customers = find_column(
        customers,
        [
            "customer_id",
            "customerid"
        ]
    )

    customer_id_orders = find_column(
        orders,
        [
            "customer_id",
            "customerid"
        ]
    )

    if (
        customer_id_customers is None
        or customer_id_orders is None
    ):

        print(
            "\nSKIP - Customer ID relationship "
            "could not be identified."
        )

        return

    master_customers = set(
        customers[
            customer_id_customers
        ]
        .dropna()
        .astype(str)
    )

    order_customers = set(
        orders[
            customer_id_orders
        ]
        .dropna()
        .astype(str)
    )

    orphan_customers = (
        order_customers
        - master_customers
    )

    if orphan_customers:

        print(
            f"FAIL - "
            f"{len(orphan_customers):,} "
            "customer IDs in orders "
            "do not exist in customer master."
        )

    else:

        print(
            "PASS - All order customer IDs "
            "exist in customer master."
        )


# ============================================================
# CUSTOMER RISK VALIDATION
# ============================================================

def calculate_customer_inactivity(
    customers: pd.DataFrame,
    orders: pd.DataFrame
) -> pd.DataFrame:
    """
    Calculate last order date and inactivity days.

    This is a validation calculation only.
    """

    customer_id_customers = find_column(
        customers,
        [
            "customer_id",
            "customerid"
        ]
    )

    customer_id_orders = find_column(
        orders,
        [
            "customer_id",
            "customerid"
        ]
    )

    order_date = find_column(
        orders,
        [
            "order_date",
            "orderdate"
        ]
    )

    if (
        customer_id_customers is None
        or customer_id_orders is None
        or order_date is None
    ):

        print(
            "\nSKIP - Required columns for "
            "inactivity analysis unavailable."
        )

        return pd.DataFrame()

    order_dates = pd.to_datetime(
        orders[order_date],
        errors="coerce"
    )

    last_orders = (
        orders.assign(
            _order_date=order_dates
        )
        .groupby(customer_id_orders)["_order_date"]
        .max()
        .reset_index()
    )

    last_orders.columns = [
        customer_id_customers,
        "last_order_date"
    ]

    result = customers[
        [customer_id_customers]
    ].drop_duplicates()

    result = result.merge(
        last_orders,
        on=customer_id_customers,
        how="left"
    )

    analysis_date = (
        order_dates.max()
    )

    result["days_inactive"] = (
        analysis_date
        - result["last_order_date"]
    ).dt.days

    result["churn_90_day_flag"] = (
        result["days_inactive"] >= CHURN_DAYS
    )

    return result


# ============================================================
# MAIN VALIDATION
# ============================================================

def main():

    print("=" * 80)
    print("CUSTOMER CHURN & REVENUE RISK ANALYSIS")
    print("CLEAN DATA VALIDATION")
    print("=" * 80)

    # ========================================================
    # LOAD DATA
    # ========================================================

    customers = load_clean_data(
        CUSTOMER_FILE,
        "Customers"
    )

    orders = load_clean_data(
        ORDER_FILE,
        "Orders"
    )

    payments = load_clean_data(
        PAYMENT_FILE,
        "Payments"
    )

    # ========================================================
    # REQUIRED COLUMNS
    # ========================================================

    check_required_columns(
        customers,
        ["customer_id"],
        "Customers"
    )

    check_required_columns(
        orders,
        ["order_id", "customer_id"],
        "Orders"
    )

    check_required_columns(
        payments,
        ["payment_id", "order_id"],
        "Payments"
    )

    # ========================================================
    # KEY VALIDATION
    # ========================================================

    validate_unique_key(
        customers,
        find_column(
            customers,
            ["customer_id", "customerid"]
        ),
        "Customers"
    )

    validate_unique_key(
        orders,
        find_column(
            orders,
            ["order_id", "orderid"]
        ),
        "Orders"
    )

    validate_unique_key(
        payments,
        find_column(
            payments,
            ["payment_id", "paymentid"]
        ),
        "Payments"
    )

    # ========================================================
    # MISSING KEY VALIDATION
    # ========================================================

    validate_missing_keys(
        customers,
        ["customer_id"],
        "Customers"
    )

    validate_missing_keys(
        orders,
        ["order_id", "customer_id"],
        "Orders"
    )

    validate_missing_keys(
        payments,
        ["payment_id", "order_id"],
        "Payments"
    )

    # ========================================================
    # DATE VALIDATION
    # ========================================================

    validate_dates(
        orders,
        [
            "order_date",
            "cancel_date",
            "cancellation_date"
        ],
        "Orders"
    )

    validate_dates(
        payments,
        [
            "payment_date",
            "transaction_date"
        ],
        "Payments"
    )

    # ========================================================
    # ORDER BUSINESS VALIDATION
    # ========================================================

    order_metrics = validate_orders(
        orders
    )

    # ========================================================
    # CHANNEL VALIDATION
    # ========================================================

    validate_channel_cancellations(
        orders
    )

    # ========================================================
    # CUSTOMER / ORDER RELATIONSHIP
    # ========================================================

    validate_customer_order_relationship(
        customers,
        orders
    )

    # ========================================================
    # CUSTOMER INACTIVITY
    # ========================================================

    customer_activity = (
        calculate_customer_inactivity(
            customers,
            orders
        )
    )

    if not customer_activity.empty:

        churned_customers = (
            customer_activity[
                "churn_90_day_flag"
            ].sum()
        )

        print(
            "\n90-Day Inactivity Check:"
        )

        print(
            f"Customers meeting "
            f"90-day inactivity rule: "
            f"{churned_customers:,}"
        )

        print(
            "Note: 90-day inactivity is the "
            "churn definition; it is NOT the "
            "same as the 2,389 At-Risk count."
        )

    # ========================================================
    # FINAL PROJECT TARGET CHECK
    # ========================================================

    print("\n" + "=" * 70)
    print("PROJECT KPI TARGET CHECK")
    print("=" * 70)

    if order_metrics["total_orders"] == EXPECTED_TOTAL_ORDERS:
        print(
            "PASS - Total Orders = 40,000"
        )
    else:
        print(
            "CHECK - Total Orders = "
            f"{order_metrics['total_orders']:,}"
        )

    if (
        order_metrics["cancelled_orders"]
        == EXPECTED_CANCELLED_ORDERS
    ):
        print(
            "PASS - Cancelled Orders = 13,381"
        )
    else:
        print(
            "CHECK - Cancelled Orders = "
            f"{order_metrics['cancelled_orders']}"
        )

    if order_metrics["cancellation_rate"] is not None:

        if abs(
            order_metrics["cancellation_rate"]
            - EXPECTED_CANCELLATION_RATE
        ) < 0.01:

            print(
                "PASS - Cancellation Rate ≈ 33.45%"
            )

        else:

            print(
                "CHECK - Cancellation Rate = "
                f"{order_metrics['cancellation_rate']:.2f}%"
            )

    # --------------------------------------------------------
    # Revenue loss
    # --------------------------------------------------------

    if order_metrics["revenue_loss"] is not None:

        print(
            "\nCalculated Revenue Loss: "
            f"₹{order_metrics['revenue_loss']:,.2f}"
        )

        print(
            "Reference Project Revenue Loss: "
            "₹2,500,000"
        )

        print(
            "IMPORTANT: Revenue loss must be "
            "reconciled against the project's "
            "defined cancellation-revenue rule "
            "before being marked as PASS."
        )

    # --------------------------------------------------------
    # At-risk customers
    # --------------------------------------------------------

    print(
        "\nReference At-Risk Customers: "
        f"{EXPECTED_AT_RISK_CUSTOMERS:,}"
    )

    print(
        "At-risk customers must be calculated "
        "using combined risk signals:"
    )

    print(
        "  1. Inactivity"
    )

    print(
        "  2. Cancellation behaviour"
    )

    print(
        "  3. Payment failures"
    )

    print(
        "\nDo NOT equate the 2,389 At-Risk "
        "customers with 90-day churn alone."
    )

    # ========================================================
    # COMPLETION
    # ========================================================

    print("\n" + "=" * 80)
    print("VALIDATION COMPLETED")
    print("=" * 80)


if __name__ == "__main__":
    main()