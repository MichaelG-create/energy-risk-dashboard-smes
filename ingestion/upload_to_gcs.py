import os
from google.cloud import storage

BUCKET_NAME = os.environ["BUCKET_NAME"]
LOCAL_PATH = "data/opsd_time_series_60min_singleindex.csv"
GCS_PATH = "raw/opsd/opsd_time_series_60min_singleindex.csv"

client = storage.Client()
bucket = client.bucket(BUCKET_NAME)
blob = bucket.blob(GCS_PATH)
blob.upload_from_filename(LOCAL_PATH)

print(f"Uploaded {LOCAL_PATH} to gs://{BUCKET_NAME}/{GCS_PATH}")