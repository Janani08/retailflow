
import os
from pathlib import Path
import snowflake.connector

files = {
    "sales_2009_2010.csv": "2009-2010",
    "sales_2010_2011.csv": "2010-2011",
}

stage = "@RETAILFLOW_DB.RAW.RETAIL_STAGE"
table = "RETAILFLOW_DB.RAW.SALES_INGEST_TEST"

conn = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_TOKEN"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    database="RETAILFLOW_DB",
    schema="RAW",
)

try:
    with conn.cursor() as cursor:
        for filename, source_year in files.items():
            path = Path("data/processed") / filename

            if not path.is_file():
                raise FileNotFoundError(path)

            print(f"Processing {filename}...")

            cursor.execute(
                f"PUT 'file://{path.resolve().as_posix()}' "
                f"{stage} AUTO_COMPRESS=TRUE OVERWRITE=FALSE"
            )

            staged_file = f"{filename}.gz"

            cursor.execute(f"""
                COPY INTO {table}
                (
                    INVOICE, STOCK_CODE, DESCRIPTION,
                    QUANTITY, INVOICE_DATE, PRICE,
                    CUSTOMER_ID, COUNTRY, SOURCE_YEAR
                )
                FROM (
                    SELECT
                        t.$1, t.$2, t.$3, t.$4,
                        t.$5, t.$6, t.$7, t.$8,
                        '{source_year}'
                    FROM {stage}/{staged_file} t
                )
                FILE_FORMAT = (
                    FORMAT_NAME = 'RETAILFLOW_DB.RAW.RETAIL_CSV_FORMAT'
                )
                ON_ERROR = ABORT_STATEMENT
            """)

            print("Load result:", cursor.fetchall())

        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        print("Total records:", cursor.fetchone()[0])

finally:
    conn.close()
