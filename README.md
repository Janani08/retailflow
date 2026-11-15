# RetailFlow
### Retail Data Engineering Pipeline

An end-to-end retail data engineering project using real transactional data to explore cloud data warehousing, historical data modeling, and automated data quality testing.

**Tech Stack:** Python · SQL · Snowflake · dbt · Data Vault 2.0 · Git · GitHub Actions (planned) · Power BI (planned)

## Project Overview

RetailFlow demonstrates how raw retail transactions can be ingested, organized, validated, and transformed into reliable datasets for business analytics.

The project uses the UCI Online Retail II dataset, containing over 1 million transactional records from a UK-based online retailer between December 2009 and December 2011.

The goal is to develop a reproducible data pipeline that supports historical analysis, data quality monitoring, and analytics-ready reporting.

## Architecture

**Planned pipeline:**

```text
UCI Online Retail II dataset
         |
         v
Python Data Ingestion
         |
         v
Snowflake RAW Layer
         |
         v
dbt Transformations
         |
         v
Data Vault 2.0
(Hubs, Links, Satellites)
         |
         v
Analytics Data Marts
         |
         v
Business Analytics
```

Automated testing and CI will be added using GitHub Actions.

## Current Implementation

**Phase 1 — Data exploration and initial warehouse setup**

- Configured an isolated Conda environment.
- Explored the original Excel dataset using pandas.
- Converted both Excel worksheets into CSV files.
- Created the Snowflake database and schemas.
- Loaded 1,067,371 transaction records into Snowflake.
- Executed initial SQL-based data profiling.

**Phase 2 — Automated Snowflake Bulk Ingestion**

- Established secure Python–Snowflake connectivity using environment variables.
- Implemented automated CSV uploads to a Snowflake internal stage.
- Used `COPY INTO` to load both CSV files into `RAW.SALES_INGEST_TEST`.
- Successfully loaded 1,067,371 transaction records.
- Populated `SOURCE_YEAR` for all records in the automated ingestion test table.
- Verified file-level duplicate prevention: repeated executions processed zero additional files and preserved the original row count.

**Current limitation:** File-level duplicate prevention relies on Snowflake's load history. Confirmed cross-file transaction duplication is handled separately in dbt staging. Comprehensive failure recovery remains under development.

**Phase 3 — dbt Transformations and Data Vault 2.0**

- Configured dbt with Snowflake and separate staging, Data Vault, and analytics schemas.
- Implemented staging transformations for standardized transaction data.
- Built three Hubs (Customer, Product, Invoice), two Links (Invoice–Product, Invoice–Customer), and three Satellites (Customer, Product, Invoice).
- Implemented incremental loading for Data Vault models.
- Verified satellite version-key uniqueness and Link-to-Hub referential integrity.
- Identified 18 product timestamp conflicts requiring careful historical interpretation.

**Phase 4 — Analytics Data Marts and Quality Testing**

- Built six analytics marts: daily sales, monthly sales, product sales, customer sales, country sales, and invoice summaries.
- Implemented automated dbt tests for key fields and uniqueness constraints.
- Added sales reconciliation tests across staging, daily, and monthly models.
- Successfully built all 15 dbt models and passed 18 automated data quality tests.

**Phase 5 — Ingestion Monitoring and Recovery**

- Implemented an ingestion audit table with `LOADED`, `SKIPPED`, and `FAILED` statuses.
- Added SHA-256 file hashing, ingestion timestamps, loaded-row counts, and error reporting.
- Verified duplicate-file skipping and failure logging.
- Updated the ingestion script to locate source files independently of the current working directory.
- Verified repeated ingestion runs without adding duplicate records.

**Remaining limitations:** Complete late-arriving-data validation, concurrent ingestion handling, and comprehensive failure recovery remain unfinished.

### Initial Data Quality Findings

| Metric | Value |
|---|---:|
| Total records | 1,067,371 |
| Unique invoices | 53,628 |
| Unique products | 5,300 |
| Missing customer IDs | 243,007 |
| Negative quantity records | 22,950 |

These results are preliminary and will be revisited during data validation.

**Known limitation:** The original manually loaded `RAW.SALES` table has an unpopulated `SOURCE_YEAR` column. The automated ingestion test table correctly populates source-period metadata.

### Cross-File Duplicate Investigation

Historical validation identified 1,088 invoice IDs appearing in both source files.

Comparison of transaction-line contents and occurrence counts confirmed that these overlapping invoices contained identical records across the two files.

A source-aware deduplication rule was implemented in dbt staging, retaining the first file's records for overlapping invoices while preserving repeated transaction lines within the retained source.

- Raw records preserved: **1,067,371**
- Cleaned staging records: **1,044,848**
- Cross-file duplicate records excluded: **22,523**

The downstream dbt models were rebuilt and all existing tests passed.

## Planned Development

- [x] Initial dataset exploration
- [x] Snowflake database setup
- [x] Initial CSV data loading
- [x] Preliminary data profiling
- [x] Automated Python ingestion (bulk loader)
- [x] dbt staging transformations
- [x] Data Vault 2.0 modeling (initial implementation)
- [x] Analytics data marts
- [x] Automated data quality tests (initial suite)
- [x] Ingestion audit logging and basic failure handling
- [ ] Final Data Vault historical and edge-case validation
- [ ] Comprehensive ingestion recovery validation
- [ ] GitHub Actions CI
- [ ] Power BI dashboard
- [ ] End-to-end reproducibility verification

## Repository Structure

```text
retailflow/
├── explore_data.py
├── prepare_data.py
├── test_snowflake_connection.py
├── load_sales.py
├── upload_to_stage.py
├── sql/
│   └── setup.sql
├── retailflow_dbt/
│   ├── dbt_project.yml
│   ├── models/
│   │   ├── staging/
│   │   ├── data_vault/
│   │   └── marts/
│   ├── macros/
│   └── tests/
├── .gitignore
└── README.md
```

Raw datasets are excluded from version control.

## Getting Started

### Prerequisites

- Python 3.11
- Conda
- Snowflake account

### Local Setup

```bash
conda create -n retail-flow python=3.11 -y
conda activate retail-flow
python -m pip install pandas openpyxl snowflake-connector-python
```

Download the UCI Online Retail II dataset and place the Excel workbook in the `data/` directory as `online_retail_II.xlsx`.

Explore the dataset:

```bash
python explore_data.py
```

Prepare the CSV files:

```bash
python prepare_data.py
```

The Snowflake database setup SQL is available in `sql/setup.sql`.

The initial warehouse load was performed manually. An automated bulk loader is now available in upload_to_stage.py. After configuring Snowflake and the required environment variables, run python upload_to_stage.py to load both CSV files into the ingestion test table.

## Dataset

**Source:** [UCI Machine Learning Repository — Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii)

The dataset contains transactional records from a UK-based online retailer.

Dataset credit belongs to the original creators and UCI Machine Learning Repository. Refer to the source page for dataset licensing and attribution requirements.

## Project Status

**In development — Phases 1–5 implemented.**

RetailFlow currently includes automated Snowflake ingestion, dbt staging transformations, incremental Data Vault models, six analytics data marts, automated data quality tests, cross-file deduplication, and ingestion audit logging.

GitHub Actions CI, Power BI reporting, final historical validation, comprehensive ingestion recovery testing, and end-to-end reproducibility verification remain upcoming milestones.