# Energy Risk Dashboard for SMEs

## Problem

Small and medium‑sized enterprises (SMEs) are highly exposed to electricity price volatility. When power prices spike, their operating costs can increase sharply, but they often lack a clear, data‑driven view of:

- How changes in wholesale power prices translate into daily/monthly energy costs.  
- How this affects their gross profit and required revenue.  
- Which SME segments are most exposed in different European price zones.

This project addresses that problem by connecting historical European day‑ahead power prices to a simplified SME P&L model and exposing risk signals in a dashboard.

## Solution 

- Ingest historical energy time series data (Open Power System Data – OPSD) into GCP (GCS + BigQuery). 
- Expose the CSV as an external raw table in BigQuery.  
- Clean and model the data with dbt (staging + mart for power prices and SME accounting). 
- Simulate a simple SME accounting model (revenue, total costs, energy costs, gross profit).  
- Compute daily energy cost and implied revenue/profit for each SME segment and price zone.  
- Build a BI dashboard in Looker Studio on top of the mart table, with:
  - Filters for date range, price zone, and SME segment.  
  - A time‑series view of energy cost vs gross profit.  
  - A bar chart comparing segments. 

## Live dashboard

A live Looker Studio dashboard (powered by the `mart_sme_energy_costs` table in BigQuery) is available here:

👉 [Live dashboard link](https://lookerstudio.google.com/reporting/3e8551a0-9426-4143-991a-14f19e0b2a69)

***

## Tech stack

- Cloud: **Google Cloud Platform** (GCS, BigQuery)  
- IaC: **Terraform** (GCS bucket, BigQuery dataset)  
- Ingestion: **Python** scripts + shell script (external table creation)  
- Transformations: **dbt** (BigQuery adapter)  
- Dashboard: **Looker Studio**  
- Languages: Python, SQL, YAML

***

## Cloud & Infrastructure

The project runs fully in GCP:

- Storage (data lake): GCS bucket `gs://$BUCKET_NAME`  
- Data warehouse: BigQuery dataset `$PROJECT_ID.$DATASET_ID` (default `energy_risk`)

### 0. Prerequisites

1. **Create a GCP project**  
   - In the Google Cloud Console, create a new project (e.g. `energy-risk-dashboard-smes`).  
   - Note the project ID.

2. **Set the project ID locally**

```bash
export PROJECT_ID="your-gcp-project-id"
```

3. **Install Google Cloud SDK** if needed:  
   https://cloud.google.com/sdk/docs/install  

4. **Initialize gcloud and select the project**

```bash
gcloud init
gcloud config set project "$PROJECT_ID"
```

5. **Configure environment variables**

From the repo root:

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

### Authentication options

You can run this project in two ways:

1. **As your own user (recommended for review/testing)**

   ```bash
   gcloud auth application-default login
   ```

   Make sure your user has:
   - BigQuery permissions on the project/dataset.  
   - Storage permissions on the bucket. 

2. **With a dedicated service account (more production‑like)**

   - Create a service account (e.g. `dbt-sa`) and grant:
     - BigQuery roles (e.g. `roles/bigquery.dataEditor` + `roles/bigquery.jobUser`).  
     - Storage Object Viewer on the GCS bucket (for the external table). 
   - Option A (JSON key):

     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="$PWD/infra/ingestion-sa-key.json"
     ```

   - Option B (no key): run dbt/terraform on a VM/runner that uses that service account directly.

For peer review, **option 1** (user ADC) is usually easiest.

***

## 1. Create GCP resources with Terraform

From `infra/`:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars  # set project_id, bucket_name, bq_dataset_id
terraform init
terraform apply
```

Terraform creates:

- A GCS bucket (`bucket_name`) for raw data.  
- A BigQuery dataset (`bq_dataset_id`, default `energy_risk`) used by dbt.

***

## 2. Download OPSD time series data

Source: Open Power System Data – time series (60min, single index). [data.open-power-system-data](https://data.open-power-system-data.org/time_series/2017-03-06/README.md)

From repo root:

```bash
uv run python ingestion/download_opsd.py
```

This downloads:

- `data/opsd_time_series_60min_singleindex.csv`

***

## 3. Upload the CSV to GCS

```bash
uv run python ingestion/upload_to_gcs.py
```

The script:

- Reads `BUCKET_NAME` from the environment.  
- Uploads:

`data/opsd_time_series_60min_singleindex.csv` →  
`gs://$BUCKET_NAME/raw/opsd/opsd_time_series_60min_singleindex.csv`.

***

## 4. Create an external table in BigQuery (raw layer)

Use the provided shell script:

```bash
./ingestion/create_external_table.sh
# or
# uv run ./ingestion/create_external_table.sh
```

This uses `PROJECT_ID`, `DATASET_ID`, and `BUCKET_NAME` and runs a BigQuery DDL similar to:

```sql
CREATE OR REPLACE EXTERNAL TABLE `${DATASET_ID}.raw_energy_prices_ext`
OPTIONS (
  format = 'CSV',
  uris = ['gs://${BUCKET_NAME}/raw/opsd/opsd_time_series_60min_singleindex.csv'],
  skip_leading_rows = 1
);
```

External table schema notes:

- `utc_timestamp`: TIMESTAMP (UTC) – parsed directly from the CSV.  
- `cet_cest_timestamp`: STRING – kept as text because the format includes offsets like `+0100` that BigQuery’s simple TIMESTAMP parser does not accept.

At this point:

- OPSD CSV is in GCS (data lake).  
- Exposed in BigQuery as `energy_risk.raw_energy_prices_ext`.

***

## 5. Transformations (dbt)

The dbt project lives in `energy_risk/` and targets the `energy_risk` dataset in BigQuery. 

### 5.1 Sources

`models/staging/sources.yml` declares the external raw table:

- Source: `energy_risk_raw`  
- Table: `raw_energy_prices_ext`  
- Documented columns:
  - `utc_timestamp`  
  - Used day‑ahead price columns, including:
    - `AT_price_day_ahead`, `DE_price_day_ahead`, `DE_AT_LU_price_day_ahead`, `DE_LU_price_day_ahead`  
    - `DK_1_price_day_ahead`, `DK_2_price_day_ahead`  
    - `GB_GBN_price_day_ahead`, `IE_sem_price_day_ahead`  
    - `IT_*_price_day_ahead` (various Italian zones)  
    - `NO_1_price_day_ahead`–`NO_5_price_day_ahead`  
    - `SE_price_day_ahead`, `SE_1_price_day_ahead`–`SE_4_price_day_ahead`

### 5.2 Seed: `sme_energy_profile`

Seed CSV: `energy_risk/seeds/sme_energy_profile.csv`.

Example (shortened):

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

- `segment` – segment name.  
- `segment_size` – size bucket (e.g. small).  
- `industry` – sector (retail, manufacturing, etc.).  
- `avg_kwh_per_day` – average daily electricity consumption.  
- `energy_cost_share` – share of total operating costs that comes from energy (0–1).  
- `base_margin_pct` – target gross margin in “normal” conditions (0–1). 

Tests (`seeds/seeds_properties.yml`):

- `not_null` + `unique` on `segment`.  
- `not_null` on numeric fields.

### 5.3 Staging model: `stg_opsd_prices`

Model: `models/staging/stg_opsd_prices.sql`.

Behavior:

- Reads from the external raw table via `{{ source('energy_risk_raw', 'raw_energy_prices_ext') }}`.  
- Selects `utc_timestamp` and all relevant `*_price_day_ahead` columns.  
- Unpivots them into a **long format** with one row per `(ts_utc, price_zone)`.

Output schema:

- `ts_utc` – UTC timestamp of the delivery hour (TIMESTAMP).  
- `price_zone` – bidding zone / price area code, e.g. `AT`, `DE_LU`, `DK_1`, `GB_GBN`, `IT_NORD`, `NO_1`, `SE_3`.  
- `price_eur_mwh` – day‑ahead price in EUR/MWh (cast to FLOAT64 for all zones). 

A `schema.yml` documents the model and adds:

- `not_null` tests on `ts_utc`, `price_zone`, `price_eur_mwh`.

### 5.4 Mart model: `mart_sme_energy_costs`

Model: `models/marts/mart_sme_energy_costs.sql`.

This model:

- Joins `stg_opsd_prices` with the `sme_energy_profile` seed via a **cross join**:
  - Each SME segment is evaluated against every price zone and timestamp.  
- Converts prices from MWh to kWh: `price_eur_kwh = price_eur_mwh / 1000`. 
- Computes daily energy cost and a simplified P&L for each `(ts_utc, price_zone, segment)`.

Key fields:

- `ts_utc` – timestamp used for partitioning.  
- `date` – calendar date `DATE(ts_utc)` for charting.  
- `price_zone` – price zone / bidding area.  
- `segment`, `segment_size`, `industry`.  
- `avg_kwh_per_day`, `energy_cost_share`, `base_margin_pct`.  
- `energy_cost_eur` – estimated daily energy cost.  
- `total_cost_eur` – approximate total operating cost.  
- `revenue_eur` – implied revenue to reach the target margin.  
- `gross_profit_eur` – simplified gross profit.

P&L formulas:

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

#### Partitioning and clustering

Configured in dbt as:

```jinja
{{ config(
    materialized = "table",
    partition_by = {
      "field": "ts_utc",
      "data_type": "timestamp",
      "granularity": "month"
    },
    cluster_by = ["price_zone", "segment"]
) }}
```

- Monthly time‑unit partitions on `ts_utc` keep the partition count well below the 4,000‑partition job limit while covering the full OPSD history. 
- Clustering by `price_zone` and `segment` improves performance for typical dashboard queries filtered by these fields. 

#### Tests and docs

`models/marts/mart_sme_energy_costs.yml` includes:

- Column descriptions for all key fields.  
- `not_null` tests on:
  - `date`  
  - `price_zone`  
  - `segment`  
  - `energy_cost_eur`  
  - `revenue_eur`  
  - `gross_profit_eur`

### 5.5 Running dbt

From repo root:

```bash
# Check dbt configuration
uv run dbt debug --project-dir energy_risk

# Load the seed
uv run dbt seed --project-dir energy_risk

# Build everything (staging + mart + tests)
uv run dbt build --project-dir energy_risk

# Or: focus on the mart and its dependencies
uv run dbt build --project-dir energy_risk --select mart_sme_energy_costs+
```

This creates:

- `energy_risk.sme_energy_profile` (seed table).  
- `energy_risk.stg_opsd_prices` (view).  
- `energy_risk.mart_sme_energy_costs` (partitioned & clustered table).

***

## 6. Dashboard (Looker Studio)

The dashboard is built in Looker Studio on top of `energy_risk.mart_sme_energy_costs`. 

### 6.1 Connect BigQuery

1. Go to https://lookerstudio.google.com  
2. Create a **Blank report**.  
3. Click **Add data → BigQuery**.  
4. Select:
   - Project: `energy-risk-dashboard-smes`  
   - Dataset: `energy_risk`  
   - Table: `mart_sme_energy_costs`  
5. Click **Add**, then **Add to report**.

Ensure `date` is typed as **Date** in the data source schema.

### 6.2 Controls

At the top of the report:

- **Date range control**  
  - Controls the `date` dimension (default date field). 
- **Dropdown filter for `price_zone`**  
- **Dropdown filter for `segment`**

These control which period, zones, and segments are filtered across all charts.

### 6.3 Charts

The report includes:

1. **Scorecards (KPIs)**  
   - Scorecard 1: `SUM(energy_cost_eur)` → “Total energy cost (selected period)”  
   - Scorecard 2: `SUM(gross_profit_eur)` → “Total gross profit (selected period)”  
   - Scorecard 3 (optional): `SUM(revenue_eur)` → “Total revenue (selected period)”

2. **Time series chart**  
   - Dimension: `date`  
   - Metrics:  
     - `SUM(energy_cost_eur)`  
     - `SUM(gross_profit_eur)`  
   - Both respect date and filter controls.

3. **Bar chart by segment**  
   - Dimension: `segment`  
   - Metric: `SUM(energy_cost_eur)` (and optionally `SUM(gross_profit_eur)`)  
   - Optional breakdown: `price_zone` (to compare across zones).

This end‑to‑end setup demonstrates:

- Cloud infra and ingestion (Terraform, GCS, external table).  
- Transformation and modeling (dbt, BigQuery, tests & docs).  
- Business‑oriented analytics (Looker Studio dashboard) tied to the SME energy risk problem.
