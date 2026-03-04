terraform {
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
}

# ==========================================
# Google Cloud Storage (Data Lake Bronze)
# ==========================================
resource "google_storage_bucket" "crypto_data_lake" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true # Only for project cleanup ease. In prod, set to false.

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30 # Delete raw files after 30 days to save costs
    }
    action {
      type = "Delete"
    }
  }
}

# ==========================================
# Google BigQuery Dataset (Target for dbt) 
# ==========================================
resource "google_bigquery_dataset" "dbt_analytics_dataset" {
  dataset_id                 = var.bq_dataset_id
  friendly_name              = "Crypto dbt Analytics"
  description                = "Dataset for storing Silver and Gold models managed by dbt Core"
  location                   = var.region
  delete_contents_on_destroy = true # Only for portfolio dev cleanup
}
