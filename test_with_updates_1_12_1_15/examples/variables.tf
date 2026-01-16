variable "project_id" {
  description = "The Google Cloud project ID to deploy the resources to."
  type        = string
}

variable "region" {
  description = "The region to deploy the App Engine application in."
  type        = string
  default     = "us-central"
}

variable "domain_name" {
  description = "A custom domain that you have verified in your GCP project (e.g., 'example.com'). The 'www' subdomain will be mapped."
  type        = string
}
