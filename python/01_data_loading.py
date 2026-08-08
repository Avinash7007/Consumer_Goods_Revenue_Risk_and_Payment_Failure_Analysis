"""
Customer Churn & Revenue Risk Analysis
Python / Pandas - Data Loading

Source files are intentionally not included in this public repository.
This script demonstrates the production loading pattern without exposing
confidential customer or transaction data.
"""

from pathlib import Path
import pandas as pd

DATA_DIR = Path("dataset")


def load_table(file_name: str) -> pd.DataFrame:
    """Load a CSV from the local/private dataset directory."""
    path = DATA_DIR / file_name
    if not path.exists():
        raise FileNotFoundError(
            f"Private source file not found: {path}. "
            "Place the approved local dataset in dataset/; do not commit it."
        )

    df = pd.read_csv(path)
    return df


if __name__ == "__main__":
    print("Data-loading template ready.")
    print("Private source data is intentionally excluded from the GitHub repository.")
