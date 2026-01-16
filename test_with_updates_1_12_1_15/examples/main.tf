terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# This example deploys a sample Python application.
# The following data source packages the local `app` directory into a zip archive.
data "archive_file" "source_zip" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "/tmp/app-source.zip"
}

# A unique suffix for the GCS bucket to ensure its name is globally unique.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# A GCS bucket to store the application source code.
resource "google_storage_bucket" "source_bucket" {
  name          = "app-engine-src-${var.project_id}-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true # Set to false in production
}

# Uploads the zipped source code to the GCS bucket.
resource "google_storage_bucket_object" "source_object" {
  name   = "source.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.source_zip.output_path
}

# Instantiate the App Engine module.
module "app_engine_example" {
  source = "../../"

  project_id  = var.project_id
  location_id = var.region

  # Define the services to be deployed.
  # This example deploys a 'default' service and a background 'api' service.
  services = {
    "default" = {
      version_id = "v1-0-0"
      runtime    = "python39"
      entrypoint = {
        shell = "gunicorn -b :$PORT main:app"
      }
      deployment = {
        zip = {
          # The source_url must point to the GCS object containing the zipped source code.
          source_url = "gs://${google_storage_bucket.source_bucket.name}/${google_storage_bucket_object.source_object.name}"
        }
      }
      # Configure automatic scaling for the default service.
      automatic_scaling = {
        max_concurrent_requests = 80
        min_instances           = 1
        max_instances           = 10
        target_cpu_utilization  = 0.75
      }
      # Send 100% of traffic to the new version.
      traffic_split = {
        allocations = {
          "v1-0-0" = 1.0
        }
      }
      env_variables = {
        ENVIRONMENT = "production"
        APP_NAME    = "My Awesome App"
      }
    },
    "api" = {
      version_id     = "v1-backend"
      runtime        = "python39"
      instance_class = "B2" # Use a backend instance class
      entrypoint = {
        shell = "gunicorn -b :$PORT main:app"
      }
      deployment = {
        zip = {
          source_url = "gs://${google_storage_bucket.source_bucket.name}/${google_storage_bucket_object.source_object.name}"
        }
      }
      # Configure basic scaling for the API service.
      basic_scaling = {
        max_instances = 5
        idle_timeout  = "10m"
      }
    }
  }

  # Map a custom domain to the App Engine application.
  # The domain must be verified in your GCP project first.
  domain_mappings = [
    {
      domain_name = "www.${var.domain_name}"
    }
  ]

  depends_on = [
    google_storage_bucket_object.source_object
  ]
}
