# Energy Risk Dashboard for SMEs

## Problem

Small and medium‑sized enterprises (SMEs) are highly exposed to electricity price volatility. When power prices spike, their operating costs can increase sharply, but they often lack a clear, data‑driven view of:

- How changes in wholesale power prices translate into daily and monthly energy costs.  
- How this affects their gross profit and required revenue.  
- Which segments are most exposed in different European price zones.

This project addresses that problem by connecting historical European day‑ahead power prices to a simplified SME P&L model and exposing risk signals in a dashboard.

## Solution (high level)

- Ingest historical energy time series data (Open Power System Data – OPSD) into GCP (GCS + BigQuery). [data.open-power-system-data](https://data.open-power-system-data.org/time_series/)
- Expose the CSV as an external raw table in BigQuery.  
- Clean and model the data with dbt (staging + mart for energy prices and SME accounting). [docs.getdbt](https://docs.getdbt.com/reference/resource-configs/bigquery-configs)
- Simulate a simple SME accounting model (revenue, costs, energy cost share, gross profit).  
- Compute daily energy cost and implied revenue/profit for each SME segment and price zone.  
- Build a BI dashboard in Looker Studio on top of the mart table, with:
  - Filters for date range, price zone, and segment.  
  - A time‑series view of energy cost vs gross profit over time.  
  - A bar chart comparing segments. [lookerstudiomasterclass](https://lookerstudiomasterclass.com/lessons/16-12-connecting-looker-studio-to-bigquery)

## Live dashboard

A live version of the Looker Studio dashboard (powered by the `mart_sme_energy_costs` table in BigQuery) is available here:

👉 [Public Looker Studio report](https://lookerstudio.google.com/reporting/3e8551a0-9426-4143-991a-14f19e0b2a69)

## Tech stack

- Cloud: **Google Cloud Platform** (GCS, BigQuery)  
- IaC: **Terraform** (GCS bucket, BigQuery dataset)  
- Ingestion: **Python** scripts + shell script (external table creation)  
- Transformations: **dbt** (BigQuery adapter)  
- Dashboard: **Looker Studio**  
- Languages: Python, SQL, YAML

***

## Cloud & Infrastructure

This project runs fully in the cloud on GCP:

- Storage (data lake): GCS bucket `gs://$BUCKET_NAME`  
- Data warehouse: BigQuery dataset `$PROJECT_ID.$DATASET_ID` (default `energy_risk`)

### Infrastructure as Code (Terraform)

Basic cloud resources (GCS bucket + BigQuery dataset) are created with Terraform in `infra/`.

From `infra/`:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars  # edit with your values (project_id, bucket_name, bq_dataset_id)

terraform init
terraform apply
```

Terraform creates:

- A GCS bucket (`bucket_name`) for raw data.  
- A BigQuery dataset (`bq_dataset_id`, default `energy_risk`) used by dbt.

***

## How to run the pipeline

### 0. Prerequisites

1. Choose a GCP project and set:

```bash
export PROJECT_ID="your-gcp-project-id"
```

2. Install Google Cloud SDK if needed:  
   https://cloud.google.com/sdk/docs/install  

3. Initialize and select the project:

```bash
gcloud init
gcloud config set project "$PROJECT_ID"
```

4. Set environment variables used by scripts and dbt:

```bash
cp .env.example .env
```

Edit `.env`:

```env
PROJECT_ID=your-gcp-project-id
BUCKET_NAME=your-gcs-bucket-name
DATASET_ID=energy_risk
```

Then load them:

```bash
set -a
source .env
set +a
```

If you use a service account key:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/infra/ingestion-sa-key.json"
```

### 1. Create GCP resources with Terraform

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars  # ensure project_id, bucket_name, etc.

terraform init
terraform apply
```

### 2. Download OPSD time series data

Source: Open Power System Data – time series (60min, single index). [data.open-power-system-data](https://data.open-power-system-data.org/time_series/2017-03-06/README.md)

From project root:

```bash
uv run python ingestion/download_opsd.py
```

This will create:

- `data/opsd_time_series_60min_singleindex.csv`

### 3. Upload the CSV to GCS

```bash
uv run python ingestion/upload_to_gcs.py
```

The script:

- Reads `BUCKET_NAME` from the environment.  
- Uploads:

`data/opsd_time_series_60min_singleindex.csv` → `gs://$BUCKET_NAME/raw/opsd/opsd_time_series_60min_singleindex.csv`.

### 4. Create an external table in BigQuery (raw layer)

Use the provided shell script:

```bash
./ingestion/create_external_table.sh
# or
# uv run ./ingestion/create_external_table.sh
```

This script uses `PROJECT_ID`, `DATASET_ID`, and `BUCKET_NAME` and runs a BigQuery DDL like:

```sql
CREATE OR REPLACE EXTERNAL TABLE `${DATASET_ID}.raw_energy_prices_ext`
OPTIONS (
  format = 'CSV',
  uris = ['gs://${BUCKET_NAME}/raw/opsd/opsd_time_series_60min_singleindex.csv'],
  skip_leading_rows = 1
);
```

In the external table schema:

- `utc_timestamp` is a TIMESTAMP column (UTC).  
- `cet_cest_timestamp` is stored as STRING (because the source format includes offsets like `+0100`). [data.open-power-system-data](https://data.open-power-system-data.org/time_series/2017-07-09/)

At this point:

- OPSD CSV is in GCS (data lake).  
- Exposed in BigQuery as `energy_risk.raw_energy_prices_ext`.

***

## Transformations (dbt)

The dbt project lives in `energy_risk/` and targets the `energy_risk` dataset in BigQuery. [docs.getdbt](https://docs.getdbt.com/best-practices/how-we-structure/2-staging)

### 1. Sources

`models/staging/sources.yml` declares the external raw table:

- Source: `energy_risk_raw`  
- Table: `raw_energy_prices_ext`  
- Documented columns:
  - `utc_timestamp`  
  - All used day‑ahead price columns, e.g. `AT_price_day_ahead`, `DE_LU_price_day_ahead`, `DK_1_price_day_ahead`, `GB_GBN_price_day_ahead`, `IT_*_price_day_ahead`, `NO_*_price_day_ahead`, `SE_*_price_day_ahead`. [data.open-power-system-data](https://data.open-power-system-data.org/time_series/2020-10-06/README.md)

### 2. Seed: `sme_energy_profile`

Seed CSV: `energy_risk/seeds/sme_energy_profile.csv`.

Example content:

```csv
segment,segment_size,industry,avg_kwh_per_day,energy_cost_share,base_margin_pct
small_retail,small,retail,50,0.15,0.20
small_manufacturing,small,manufacturing,500,0.25,0.18
restaurant,small,hospitality,200,0.30,0.22
small_office,small,services,30,0.12,0.25
small_warehouse,small,logistics,80,0.18,0.15
small_grocery,small,retail,120,0.20,0.18
bakery,small,food_production,150,0.28,0.20
small_hotel,small,accommodation,250,0.27,0.22
clinic,small,healthcare,90,0.18,0.24
coworking_space,small,services,60,0.14,0.25
```

Each row defines a synthetic SME **segment archetype** with:

- `segment`: name of the archetype.  
- `segment_size`: size bucket (e.g. small).  
- `industry`: sector (retail, manufacturing, hospitality, etc.).  
- `avg_kwh_per_day`: average daily electricity consumption (kWh/day).  
- `energy_cost_share`: share of operating costs that comes from energy (0–1).  
- `base_margin_pct`: target gross margin under “normal” conditions (0–1). [edfenergy](https://www.edfenergy.com/energywise/small-business-energy-usage)

### 3. Staging model: `stg_opsd_prices`

Model: `models/staging/stg_opsd_prices.sql`.

This model:

- Reads from the external raw table via `{{ source('energy_risk_raw', 'raw_energy_prices_ext') }}`.  
- Selects `utc_timestamp` and all relevant `*_price_day_ahead` columns, e.g.:

  - `AT_price_day_ahead`  
  - `DE_price_day_ahead`  
  - `DE_AT_LU_price_day_ahead`  
  - `DE_LU_price_day_ahead`  
  - `DK_1_price_day_ahead`, `DK_2_price_day_ahead`  
  - `GB_GBN_price_day_ahead`  
  - `IE_sem_price_day_ahead`  
  - `IT_*_price_day_ahead`  
  - `NO_*_price_day_ahead`  
  - `SE_price_day_ahead`, `SE_1_price_day_ahead`, `SE_2_price_day_ahead`, `SE_3_price_day_ahead`, `SE_4_price_day_ahead`.

- Unpivots them into a **long format**:

  - `ts_utc` – UTC timestamp (TIMESTAMP).  
  - `price_zone` – bidding zone / price area (e.g. `AT`, `DE_LU`, `DK_1`, `GB_GBN`, `IT_NORD`, `NO_1`, `SE_3`).  
  - `price_eur_mwh` – day‑ahead price in EUR/MWh (casted to FLOAT64).

So each row in `stg_opsd_prices` represents:

> “At timestamp `ts_utc`, in price zone `price_zone`, the day‑ahead price is `price_eur_mwh` EUR/MWh.”

A `schema.yml` file documents the model and adds basic tests:

- `not_null` on `ts_utc`, `price_zone`, `price_eur_mwh`. [docs.getdbt](https://docs.getdbt.com/reference/resource-properties/columns)

### 4. Mart: `mart_sme_energy_costs`

Model: `models/marts/mart_sme_energy_costs.sql`.

This model:

- Joins `stg_opsd_prices` with the `sme_energy_profile` seed using a **cross join** (each SME segment is applied to every price zone).  
- Converts prices from MWh to kWh: `price_eur_kwh = price_eur_mwh / 1000`. [renogy](https://www.renogy.com/blogs/buyers-guide/kwh-to-mwh-conversion-guide)
- Computes daily energy cost and a simplified P&L for each `(ts_utc, segment, price_zone)`.

Key fields:

- `ts_utc` – timestamp (used for partitioning).  
- `date` – calendar date `DATE(ts_utc)` for charting.  
- `price_zone` – price zone / bidding area.  
- `segment`, `segment_size`, `industry`.  
- `avg_kwh_per_day`, `energy_cost_share`, `base_margin_pct`.  
- `energy_cost_eur` – estimated daily energy cost.  
- `total_cost_eur` – approximate total operating cost given the energy cost share.  
- `revenue_eur` – implied revenue to reach the target margin.  
- `gross_profit_eur` – simplified gross profit.

The P&L logic:

1. Daily energy cost:

\[
energy\_cost\_eur = avg\_kwh\_per\_day \times price\_eur\_kwh
\]

2. Total operating cost (energy is `energy_cost_share` of total cost):

\[
total\_cost\_eur = \frac{energy\_cost\_eur}{energy\_cost\_share}
\]

3. Revenue needed to hit `base_margin_pct`:

\[
revenue\_eur = \frac{total\_cost\_eur}{1 - base\_margin\_pct}
\]

4. Gross profit:

\[
gross\_profit\_eur = revenue\_eur - total\_cost\_eur
\]

These formulas are implemented directly in the mart SQL.

#### Partitioning and clustering

The mart is configured in dbt as:

- `materialized = "table"`  
- `partition_by` on `ts_utc` (TIMESTAMP) with **monthly** granularity.  
- `cluster_by` on `["price_zone", "segment"]`.

This reduces the number of partitions (monthly instead of daily) and improves query performance when filtering by time and price zone. [owox](https://www.owox.com/blog/articles/bigquery-partitioned-tables)

#### Tests and documentation

A `schema.yml` for the mart includes:

- Descriptions for key columns.  
- `not_null` tests on:
  - `date`  
  - `price_zone`  
  - `segment`  
  - `energy_cost_eur`  
  - `revenue_eur`  
  - `gross_profit_eur`. [docs.getdbt](https://docs.getdbt.com/reference/resource-properties/data-tests)

### 5. Running dbt

From the project root:

```bash
# Check dbt configuration
uv run dbt debug --project-dir energy_risk

# Load the seed
uv run dbt seed --project-dir energy_risk

# Build everything (staging + mart + tests)
uv run dbt build --project-dir energy_risk

# Or to focus on the mart and its upstream dependencies:
uv run dbt build --project-dir energy_risk --select mart_sme_energy_costs+
```

This creates:

- `energy_risk.sme_energy_profile` (seed table)  
- `energy_risk.stg_opsd_prices` (view)  
- `energy_risk.mart_sme_energy_costs` (table, partitioned & clustered)

***

## Dashboard (Looker Studio)

The dashboard is built on top of `energy_risk.mart_sme_energy_costs` in Looker Studio. [lookerstudiomasterclass](https://lookerstudiomasterclass.com/blog/connect-bigquery-looker-studio-visualization)

### 1. Connect BigQuery

1. Go to https://lookerstudio.google.com  
2. Create a **Blank report**.  
3. Click **Add data → BigQuery**.  
4. Select:
   - Project: `energy-risk-dashboard-smes`  
   - Dataset: `energy_risk`  
   - Table: `mart_sme_energy_costs`  
5. Click **Add**, then **Add to report**.

### 2. Filters and controls

At the top of the report:

- **Date range control**  
  - Controls the `date` field (set as Date type in the data source).  
- **Drop‑down filter for `price_zone`**  
- **Optional drop‑down filter for `segment`**

These controls allow the user to explore different periods, price zones and SME segments.

### 3. Charts

The report includes at least:

1. **Scorecards (KPIs)**  
   - Total energy cost for the selected period:  
     - Metric: `SUM(energy_cost_eur)`  
   - Total gross profit:  
     - Metric: `SUM(gross_profit_eur)`  
   - Optional: total revenue:  
     - Metric: `SUM(revenue_eur)`.  

2. **Time series chart**  
   - Dimension: `date`  
   - Metrics:  
     - `SUM(energy_cost_eur)`  
     - `SUM(gross_profit_eur)`  
   - Filters inherited from the date range control and the `price_zone` / `segment` filters.

3. **Bar chart by segment**  
   - Dimension: `segment`  
   - Metric: `SUM(energy_cost_eur)` (and optionally `SUM(gross_profit_eur)`)  
   - Breakdown dimension (optional): `price_zone`  
   - Shows which SME archetypes are most exposed to energy cost in each zone.

This dashboard closes the loop:

- Cloud infra and ingestion (Terraform, Python, GCS, external table).  
- Transformations and modeling (dbt, BigQuery).  
- Business‑oriented visualization (Looker Studio), tied back to the original problem of SME energy risk.

