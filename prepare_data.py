import pandas as pd
from pathlib import Path

source = Path("data/online_retail_II.xlsx")
output = Path("data/processed")
output.mkdir(parents=True, exist_ok=True)

sheets = {
    "Year 2009-2010": "sales_2009_2010.csv",
    "Year 2010-2011": "sales_2010_2011.csv",
}

for sheet, filename in sheets.items():
    print(f"Processing {sheet}...")

    df = pd.read_excel(
        source,
        sheet_name=sheet,
        dtype={"Invoice": str, "StockCode": str, "Customer ID": str}
    )

    df.to_csv(output / filename, index=False)

    print(f"Saved {filename}: {len(df):,} rows")