download_opsd:
\tpython ingestion/download_opsd.py

upload_opsd:
\tpython ingestion/upload_to_gcs.py

pipeline_opsd: download_opsd upload_opsd load_opsd_bq

dbt_debug:
	uv run dbt debug --project-dir energy_risk

dbt_run:
	uv run dbt run --project-dir energy_risk

dbt_build:
	uv run dbt build --project-dir energy_risk