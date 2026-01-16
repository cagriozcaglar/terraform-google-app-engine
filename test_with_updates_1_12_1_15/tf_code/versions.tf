# This file contains the provider requirements for the Terraform module.
terraform {
  # Specifies the required Terraform version.
  required_version = ">= 1.0"
  # Specifies the required providers and their versions.
  required_providers {
    # Defines the Google Cloud Platform provider.
    google = {
      # The source of the provider, in this case, from HashiCorp's registry.
      source  = "hashicorp/google"
      # The minimum required version of the Google provider.
      version = ">= 4.50.0"
    }
  }
}
