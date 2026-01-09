terraform {
  # Specifies the minimum required version of Terraform.
  required_version = ">= 1.2.0"

  required_providers {
    # Defines the required provider for Google Cloud Platform.
    google = {
      # The official HashiCorp Google Cloud provider.
      source = "hashicorp/google"
      # Specifies the version constraint for the provider.
      version = "~> 5.20"
    }
  }
}
