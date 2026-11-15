
import hashlib
import os
from pathlib import Path

import snowflake.connector


FILES = {
    "sales_2009_2010.csv": "2009-2010",
    "sales_2010_2011.csv": "2010-2011",
}

STAGE = "@RETAILFLOW_DB.RAW.RETAIL_STAGE"
TARGET = "RETAILFLOW_DB.RAW.SALES_INGEST_TEST"
AUDIT = "RETAILFLOW_DB.RAW.INGESTION_AUDIT"


def file_hash(path):
    digest = hashlib.sha256()

    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)

    return digest.hexdigest()


def record_attempt(cursor, filename, checksum, status, rows, error=None):
    cursor.execute(
        f"""
        INSERT INTO {AUDIT}
            (FILE_NAME, FILE_HASH, STATUS, ROWS_LOADED, ERROR_MESSAGE)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (filename, checksum, status, rows, error),
    )


def main():
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
            cursor.execute(f"""
                CREATE TABLE IF NOT EXISTS {AUDIT} (
                    FILE_NAME VARCHAR,
                    FILE_HASH VARCHAR,
                    STATUS VARCHAR,
                    ROWS_LOADED INTEGER,
                    ERROR_MESSAGE VARCHAR,
                    ATTEMPTED_AT TIMESTAMP_LTZ
                        DEFAULT CURRENT_TIMESTAMP()
                )
            """)

            for filename, source_year in FILES.items():
                path = Path(__file__).resolve().parent / "data" / "processed" / filename
                checksum = None

                print(f"\nProcessing {filename}...")

                try:
                    if not path.is_file():
                        raise FileNotFoundError(path)

                    checksum = file_hash(path)

                    # Reject changed content under an already audited filename.
                    cursor.execute(
                        f"""
                        SELECT COUNT(*)
                        FROM {AUDIT}
                        WHERE FILE_NAME = %s
                          AND STATUS IN ('LOADED', 'SKIPPED')
                          AND FILE_HASH <> %s
                        """,
                        (filename, checksum),
                    )

                    if cursor.fetchone()[0] > 0:
                        raise ValueError(
                            "File content changed under the same filename. "
                            "Review before reloading."
                        )

                    cursor.execute(
                        f"PUT 'file://{path.resolve().as_posix()}' "
                        f"{STAGE} AUTO_COMPRESS=TRUE OVERWRITE=FALSE"
                    )

                    staged_file = f"{filename}.gz"

                    cursor.execute(f"""
                        COPY INTO {TARGET}
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
                            FROM {STAGE}/{staged_file} t
                        )
                        FILE_FORMAT = (
                            FORMAT_NAME =
                            'RETAILFLOW_DB.RAW.RETAIL_CSV_FORMAT'
                        )
                        ON_ERROR = ABORT_STATEMENT
                    """)

                    results = cursor.fetchall()

                    if (
                        len(results) == 1
                        and len(results[0]) == 1
                        and results[0][0] ==
                        "Copy executed with 0 files processed."
                    ):
                        status = "SKIPPED"
                        rows_loaded = 0

                    else:
                        if not results or any(
                            len(row) < 6
                            or row[1] != "LOADED"
                            or row[5] != 0
                            for row in results
                        ):
                            raise RuntimeError(
                                f"Unexpected COPY result: {results}"
                            )

                        status = "LOADED"
                        rows_loaded = sum(row[3] for row in results)

                    record_attempt(
                        cursor, filename, checksum,
                        status, rows_loaded
                    )

                    print(f"{status}: {rows_loaded} new rows")

                except Exception as error:
                    print(f"FAILED: {filename}: {error}")

                    try:
                        record_attempt(
                            cursor, filename, checksum,
                            "FAILED", 0, str(error)
                        )
                    except Exception as log_error:
                        print(f"Audit logging also failed: {log_error}")

                    raise

            cursor.execute(f"SELECT COUNT(*) FROM {TARGET}")
            print("\nTotal RAW records:", cursor.fetchone()[0])

    finally:
        conn.close()


if __name__ == "__main__":
    main()
