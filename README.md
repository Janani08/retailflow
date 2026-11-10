# RetailFlow
### Retail Data Engineering Pipeline

An end-to-end retail data engineering project using real transactional data to explore cloud data warehousing, historical data modeling, and automated data quality testing.

**Tech Stack:** Python · SQL · Snowflake · dbt (planned) · Data Vault 2.0 (planned) · GitHub Actions (planned)

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

### Initial Data Quality Findings

| Metric | Value |
|---|---:|
| Total records | 1,067,371 |
| Unique invoices | 53,628 |
| Unique products | 5,300 |
| Missing customer IDs | 243,007 |
| Negative quantity records | 22,950 |

These results are preliminary and will be revisited during data validation.

**Known limitation:** The initial manual load did not capture source-file metadata. The `SOURCE_YEAR` column is currently unpopulated. Proper ingestion metadata and reproducible loading are planned.

## Planned Development

- [x] Initial dataset exploration
- [x] Snowflake database setup
- [x] Initial CSV data loading
- [x] Preliminary data profiling
- [ ] Automated Python ingestion
- [ ] dbt staging transformations
- [ ] Data Vault 2.0 modeling
- [ ] Analytics data marts
- [ ] Automated data quality tests
- [ ] GitHub Actions CI
- [ ] End-to-end reproducibility verification

## Repository Structure

```text
retailflow/
├── explore_data.py
├── prepare_data.py
├── sql/
│   └── setup.sql
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
python -m pip install pandas openpyxl
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

The initial warehouse load was performed manually through Snowflake's interface. Automated loading instructions will be added as the project develops.

## Dataset

**Source:** [UCI Machine Learning Repository — Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii)

The dataset contains transactional records from a UK-based online retailer.

Dataset credit belongs to the original creators and UCI Machine Learning Repository. Refer to the source page for dataset licensing and attribution requirements.

## Project Status

**In development — Phase 1 completed.**

The current implementation establishes the source data preparation process and initial Snowflake warehouse. Data modeling, transformation automation, and CI are upcoming milestones.