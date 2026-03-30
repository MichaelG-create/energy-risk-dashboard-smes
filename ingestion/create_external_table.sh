#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Need PROJECT_ID}"
: "${DATASET_ID:?Need DATASET_ID}"
: "${BUCKET_NAME:?Need BUCKET_NAME}"

TABLE_ID="raw_energy_prices_ext"
GCS_URI="gs://${BUCKET_NAME}/raw/opsd/opsd_time_series_60min_singleindex.csv"

bq query \
  --project_id="${PROJECT_ID}" \
  --use_legacy_sql=false \
  "
  CREATE OR REPLACE EXTERNAL TABLE \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\`
  OPTIONS (
    format = 'CSV',
    uris = ['${GCS_URI}'],
    skip_leading_rows = 1
  );
  "