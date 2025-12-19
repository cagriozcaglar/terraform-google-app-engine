terraform {
  # This block specifies the provider requirements for this module.
  required_providers {
    # This module requires the Google Provider.
    google = {
      # The source of the provider, in this case, the official HashiCorp provider.
      source = "hashicorp/google"
      # The required version constraint for the Google provider.
      version = ">= 4.50.0"
    }
  }
  # Specifies the minimum required version of Terraform to apply this configuration.
  required_version = ">= 1.0"
}
