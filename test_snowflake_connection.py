import os
import snowflake.connector

conn = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_TOKEN"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    database="RETAILFLOW_DB",
    schema="RAW",
)

try:
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT CURRENT_VERSION()")
        print("Connected to Snowflake!")
        print("Version:", cursor.fetchone()[0])

        cursor.execute("SELECT COUNT(*) FROM RETAILFLOW_DB.RAW.SALES")
        print("RetailFlow records:", cursor.fetchone()[0])
    finally:
        cursor.close()
finally:
    conn.close()