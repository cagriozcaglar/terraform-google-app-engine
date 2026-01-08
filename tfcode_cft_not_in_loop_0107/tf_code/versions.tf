terraform {
  # This module is designed to work with Terraform 1.3 and newer.
  required_version = ">= 1.3"

  required_providers {
    # Google Provider version 4.34.0 or newer is required.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}
