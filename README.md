# Energy Risk Dashboard for SMEs

## Problem

Small and medium businesses are highly exposed to energy price volatility. When energy prices spike, their operating costs can increase dramatically, but they often lack a clear, data-driven view of the impact on their profit and cash runway.

This project builds an end-to-end data pipeline that connects historical energy price data to a simplified SME P&L, so decision-makers can see when energy costs become dangerous and how different scenarios affect their survival.

## Solution (high level)

- Ingest historical energy time series data (Open Power System Data) into Google Cloud (GCS + BigQuery).
- Clean and model the data with dbt (staging + marts for energy prices and SME accounting).
- Simulate a simple SME accounting model (revenue, fixed costs, variable costs, energy costs).
- Compute basic risk indicators (energy cost share, simple volatility, risk flags).
- Build a BI dashboard (Looker Studio) with:
  - A categorical view of cost structure (energy vs other costs).
  - A time-series view of profit and energy prices/costs over time.

## Tech stack

- Cloud: GCP (GCS, BigQuery)
- Orchestration: (simple scripts / optional scheduler)
- Transformations: dbt (BigQuery)
- Dashboard: Looker Studio
- Language: Python, SQL

## How to run (WIP)

1. At https://console.cloud.google.com/ , create a GCP project, a GCS bucket and a BigQuery dataset (e.g. `energy_risk`) or directly with gcloud:
```bash
# Create a project (replace PROJECT_ID by your unique project ID)
gcloud projects create PROJECT_ID

# select your project as active project
gcloud config set project PROJECT_ID

# Create a GCS bucket (replace BUCKET_NAME by a unique ID, ex: energy-risk-bucket-xxxx)
gsutil mb -l EU gs://energy-risk-bucket-123456/

# activate BigQuery
gcloud services enable bigquery.googleapis.com

# create the dataset
bq --location=EU mk --dataset PROJECT_ID:energy_risk

```
2. Configure credentials locally so Python and dbt can access BigQuery.
3. Run the ingestion script/notebook to load energy data into `raw_energy_prices`.
4. Run dbt to build staging and mart models.
5. Connect Looker Studio to BigQuery and open the dashboard.

More detailed instructions will be added as the project evolves.