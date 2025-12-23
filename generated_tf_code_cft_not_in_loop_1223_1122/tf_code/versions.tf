terraform {
  # Specifies the required version of Terraform to run this module.
  required_version = ">= 1.3"

  # Specifies the required version of the Google Cloud provider.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}
