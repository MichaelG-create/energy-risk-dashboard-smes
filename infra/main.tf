terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file("terraform-sa-key.json")
}

resource "google_storage_bucket" "energy_risk_bucket" {
  name          = var.bucket_name
  location      = upper(var.region)
  storage_class = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_bigquery_dataset" "energy_risk_dataset" {
  dataset_id  = var.bq_dataset_id
  project     = var.project_id
  location    = upper(var.region)
}