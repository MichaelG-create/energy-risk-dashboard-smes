import os
import requests

OPSD_URL = "https://data.open-power-system-data.org/time_series/2019-06-05/time_series_60min_singleindex.csv"
LOCAL_DIR = "data"
LOCAL_PATH = os.path.join(LOCAL_DIR, "opsd_time_series_60min_singleindex.csv")

os.makedirs(LOCAL_DIR, exist_ok=True)

resp = requests.get(OPSD_URL)
resp.raise_for_status()

with open(LOCAL_PATH, "wb") as f:
    f.write(resp.content)

print(f"Downloaded to {LOCAL_PATH}")