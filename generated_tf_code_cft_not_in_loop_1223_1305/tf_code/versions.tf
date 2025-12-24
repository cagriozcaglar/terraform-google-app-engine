terraform {
  # required_version: The minimum version of Terraform required to run this configuration.
  required_version = ">= 1.0"
  required_providers {
    # google: The Google Cloud provider.
    google = {
      # source: The source of the provider.
      source  = "hashicorp/google"
      # version: The version constraint for the provider.
      version = "~> 5.0"
    }
  }
}
