
import os
import csv
import json
import hashlib
from pathlib import Path
from datetime import datetime
from decimal import Decimal
import snowflake.connector

# Read the first 100 records for testing
file_path = Path("data/processed/sales_2009_2010.csv")

with file_path.open(encoding="utf-8-sig", newline="") as f:
    reader = csv.DictReader(f)
    sample = []

    for row in reader:
        if len(sample) == 100:
            break
        sample.append(row)

# Create a fingerprint of the exact sample
sample_bytes = json.dumps(
    sample, sort_keys=True
).encode("utf-8")

file_hash = hashlib.sha256(sample_bytes).hexdigest()
file_name = file_path.name + ":first100"

# Prepare data for Snowflake
rows = [
    (
        r["Invoice"],
        r["StockCode"],
        r["Description"] or None,
        int(r["Quantity"]),
        datetime.fromisoformat(r["InvoiceDate"]),
        Decimal(r["Price"]),
        r["Customer ID"] or None,
        r["Country"],
        "2009-2010"
    )
    for r in sample
]

# Connect to Snowflake
conn = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_TOKEN"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    database="RETAILFLOW_DB",
    schema="RAW",
    autocommit=False
)

try:
    cursor = conn.cursor()

    try:
        # Check if this exact sample was loaded before
        cursor.execute("""
            SELECT COUNT(*)
            FROM RAW.INGESTION_LOG
            WHERE FILE_HASH = %s
        """, (file_hash,))

        already_loaded = cursor.fetchone()[0] > 0

        if already_loaded:
            print("Sample already processed. Skipping.")

        else:
            cursor.executemany("""
                INSERT INTO RAW.SALES_INGEST_TEST
                (INVOICE, STOCK_CODE, DESCRIPTION,
                 QUANTITY, INVOICE_DATE, PRICE,
                 CUSTOMER_ID, COUNTRY, SOURCE_YEAR)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, rows)

            cursor.execute("""
                INSERT INTO RAW.INGESTION_LOG
                (FILE_NAME, FILE_HASH, ROW_COUNT)
                VALUES (%s, %s, %s)
            """, (file_name, file_hash, len(rows)))

            conn.commit()
            print(f"Successfully loaded {len(rows)} records.")

        cursor.execute("""
            SELECT COUNT(*) FROM RAW.SALES_INGEST_TEST
        """)
        print("Total test records:", cursor.fetchone()[0])

    finally:
        cursor.close()

except Exception:
    conn.rollback()
    raise

finally:
    conn.close()
