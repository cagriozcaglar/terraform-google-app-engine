# The terraform block is used to configure aspects of Terraform's behavior.
terraform {
  # Specifies the required providers and their versions.
  required_providers {
    # The Google Cloud provider is required for managing Google Cloud resources.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}
