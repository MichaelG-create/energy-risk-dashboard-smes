# Energy Risk Dashboard for SMEs

## Problem

Small and medium businesses are highly exposed to energy price volatility. When energy prices spike, their operating costs can increase dramatically, but they often lack a clear, data‑driven view of:

- how energy price changes translate into monthly costs and profit,
- how long they can “survive” under crisis prices (cash runway),
- and when they should start taking action (risk thresholds).

This project solves that problem by connecting historical energy prices to a simplified SME P&L and exposing risk signals in a dashboard.

## Solution (high level)

- Ingest historical energy time series data (Open Power System Data) into Google Cloud (GCS + BigQuery). [data.open-power-system-data](https://data.open-power-system-data.org/time_series/)
- Clean and model the data with dbt (staging + marts for energy prices and SME accounting).
- Simulate a simple SME accounting model (revenue, fixed costs, variable costs, energy costs).
- Compute basic risk indicators (energy cost share, simple volatility, risk flags).
- Build a BI dashboard (Looker Studio) with:
  - a categorical view of cost structure (energy vs other costs),
  - a time‑series view of profit and energy prices/costs over time.

## Tech stack

- Cloud: GCP (GCS, BigQuery)
- IaC: Terraform (bucket + BigQuery dataset)
- Orchestration: simple scripts / (optional) Makefile or scheduler
- Transformations: dbt (BigQuery)
- Dashboard: Looker Studio
- Language: Python, SQL

## Cloud & Infrastructure

This project runs fully in the cloud on GCP:

- Storage: GCS (`$BUCKET_NAME`) as the data lake.
- Data Warehouse: BigQuery (`$PROJECT_ID.$DATASET_ID`) as the serving layer.

***

### Infrastructure as Code (Terraform)

Basic cloud resources (GCS bucket + BigQuery dataset) are created with Terraform.

#### 0. Authentication model

For this project you can:

- Use **user credentials** (simplest): `gcloud auth application-default login`, or  
- Use a **Service Account key**, created even if your org normally blocks key creation, by temporarily relaxing the org policy.

##### Temporary org policy change to allow SA key creation

Some organizations enforce the `constraints/iam.disableServiceAccountKeyCreation` policy, which blocks new service account keys. [docs.cloud.google](https://docs.cloud.google.com/organization-policy/restrict-service-accounts)
If you have the right permissions at the org level (e.g. Organization Policy Administrator), you can:

1. **Find your organization ID**  
   - In the GCP web console (top resource selector) or via:

     ```bash
     gcloud organizations list
     ```

2. **Temporarily disable enforcement for key creation**

   ```bash
   gcloud resource-manager org-policies disable-enforce \
     iam.disableServiceAccountKeyCreation \
     --organization=ORG_ID
   ```

   Alternatively, you can do it in the console:  
   IAM & Admin → Organization Policies → search for `Disable service account key creation` → Manage Policy → set Enforcement to Off → Save. [security.googlecloudcommunity](https://security.googlecloudcommunity.com/google-security-operations-2/service-account-key-creation-is-disabled-213)

3. **Create the service account and one key**

   - Create the SA (via console or `gcloud iam service-accounts create`),  
   - Grant it the required roles (Storage, BigQuery, etc.),  
   - Create a JSON key and download it locally (e.g. `infra/sa-key.json` — do **not** commit this file).

4. **Re‑enable the org policy**

   Immediately re‑enforce the constraint after downloading the key:

   ```bash
   gcloud resource-manager org-policies enable-enforce \
     iam.disableServiceAccountKeyCreation \
     --organization=ORG_ID
   ```

   This restores the protection so no one can create new keys anymore. [oneuptime](https://oneuptime.com/blog/post/2026-02-17-how-to-enforce-service-account-key-creation-restrictions-with-organization-policies/view)

Now you can point Terraform to that local JSON key (for example by setting `GOOGLE_APPLICATION_CREDENTIALS`).

#### 1. Initialize and apply

From the `infra/` directory:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # edit with your values (project_id, bucket_name, bq_dataset_id)

terraform init
terraform apply
```

Terraform will create:

- a GCS bucket (`bucket_name`) for raw data,
- a BigQuery dataset (`bq_dataset_id`, default `energy_risk`) for the warehouse.

***

## How to run (data pipeline – WIP)

### 0. Set your project ID, install gcloud and authenticate

First, choose a GCP project ID and export it:

```bash
export PROJECT_ID="your-gcp-project-id"
```

Install the Google Cloud SDK if needed:  
https://cloud.google.com/sdk/docs/install

Then initialize and log in:

```bash
gcloud init
```

Configure the active project and Application Default Credentials:

```bash
gcloud config set project "$PROJECT_ID"
gcloud auth application-default login
```

Terraform and the Google client libraries will use these credentials.

### 1. Configure local environment variables

This project uses environment variables for configuration.  
You can use the provided `.env.example` as a template.

At the project root:

```bash
cp .env.example .env
```

Edit `.env` and set your values (PROJECT_ID should match the one above):

```env
PROJECT_ID=your-gcp-project-id
BUCKET_NAME=your-gcs-bucket-name
DATASET_ID=energy_risk
```

Then export them in your shell:

```bash
set -a
source .env
set +a
```

### 2. Create GCP resources with Terraform

From the `infra/` directory:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # edit with your values (project_id, bucket_name, etc.)

terraform init
terraform apply
```

### 3. Download the OPSD time series data

Source: Open Power System Data – time series (60min, single index). [data.open-power-system-data](https://data.open-power-system-data.org/time_series/)

```bash
mkdir -p ./data
wget -P ./data/ https://data.open-power-system-data.org/time_series/2020-10-06/time_series_60min_singleindex.csv
```

### 4. Upload the CSV to GCS

```bash
gsutil cp data/time_series_60min_singleindex.csv \
  "gs://$BUCKET_NAME/raw/opsd/time_series_60min_singleindex.csv"
```

### 5. Load from GCS into BigQuery (raw layer)

```bash
bq load \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  "$PROJECT_ID:$DATASET_ID.raw_energy_prices" \
  "gs://$BUCKET_NAME/raw/opsd/time_series_60min_singleindex.csv"
```

At this point you have a `raw_energy_prices` table in BigQuery (dataset `energy_risk`) populated with the OPSD time series data.

### 6. Next steps

1. Configure dbt to point to your BigQuery dataset.
2. Create staging models (e.g. `stg_opsd_prices`) and marts (e.g. `mart_sme_energy_costs`).
3. Connect Looker Studio to BigQuery and build the dashboard.

More detailed instructions will be added as the project evolves.