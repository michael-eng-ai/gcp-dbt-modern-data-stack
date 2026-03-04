variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
  default     = "fake-gcp-project-123456" # Replace with your real project ID via TF_VAR_project_id
}

variable "region" {
  description = "The Google Cloud region for resources"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "Name for the GCS bucket used as a Data Lake"
  type        = string
  default     = "raw-crypto-data-lake-19542" # Ensuring global uniqueness suffix
}

variable "bq_dataset_id" {
  description = "BigQuery Dataset ID for dbt core transformation target"
  type        = string
  default     = "crypto_dbt_analytics"
}
