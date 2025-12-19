# Terraform Google Cloud App Engine Module

This module handles the creation and configuration of a Google Cloud App Engine application. It simplifies deploying multiple services in both standard and flexible environments, configuring scaling, and managing traffic splits between different versions.

## Usage

Basic usage of this module is as follows:

```hcl
module "app_engine" {
  source      = "path/to/module"
  project_id  = "your-gcp-project-id"
  location_id = "us-central"

  // Example of a standard service
  standard_services = {
    "default" = {
      version_id            = "v1"
      runtime               = "python311"
      entrypoint_shell      = "gunicorn -b :$PORT main:app"
      deployment_source_url = "gs://my-app-source-bucket/default-service.zip"
      instance_class        = "F1"
      scaling = {
        automatic_scaling = {
          min_idle_instances = 1
          max_idle_instances = 5
          standard_scheduler_settings = {
            max_instances = 10
          }
        }
      }
    }
  }

  // Example of a flexible service from a container image
  flexible_services = {
    "api-service" = {
      version_id           = "v1-flex"
      deployment_image_url = "gcr.io/your-gcp-project-id/api-image:latest"
      resources = {
        cpu       = 2
        memory_gb = 2
      }
      automatic_scaling = {
        min_total_instances = 1
        max_total_instances = 3
        cpu_utilization = {
          target_utilization = 0.75
        }
      }
      readiness_check = {
        path = "/readiness_check"
      }
    }
  }

  // Example of traffic splitting for the default service
  traffic_splits = {
    "default" = {
      shard_by = "RANDOM"
      allocations = {
        "v1" = 1.0 // Allocate 100% of traffic to version 'v1'
      }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `auth_domain` | The custom domain to use for authenticating users. Leave null to use the default Google accounts domain. | `string` | `null` | no |
| `database_type` | The type of database to use. Can be 'CLOUD\_FIRESTORE' or 'CLOUD\_DATASTORE\_COMPATIBILITY'. Leave null to use the default. | `string` | `null` | no |
| `feature_settings` | A configuration block for feature settings of the App Engine application. | <pre>object({<br>  split_health_checks = bool<br>})</pre> | `{ split_health_checks = true }` | no |
| `flexible_services` | A map of flexible App Engine services to create, with one version per service definition.<br>The key of the map is the service name.<br><br>Each service object has the following attributes:<br>- `version_id`: (Optional) The ID for this version. Defaults to 'v1-flex'.<br>- `runtime`: (Optional) The runtime environment. Defaults to 'custom' for containers.<br>- `deployment_image_url`: (Required) The full URL of the container image to deploy.<br>- `env_variables`: (Optional) A map of environment variables.<br>- `noop_on_destroy`: (Optional) If true, prevents Terraform from deleting the version. Defaults to true.<br>- `serving_status`: (Optional) The serving status of the version. Defaults to 'SERVING'.<br>- `liveness_check`: (Optional) Configuration for liveness health checks.<br>- `readiness_check`: (Optional) Configuration for readiness health checks.<br>- `resources`: (Optional) Machine resource settings like `cpu`, `memory_gb`, and `disk_gb`.<br>- `network`: (Optional) Network configuration for the service.<br>- `automatic_scaling`: (Optional) Automatic scaling settings for the service. | `map(any)` | `{}` | no |
| `iap` | Configuration for Identity-Aware Proxy (IAP). If set, IAP will be enabled for the application. | <pre>object({<br>  oauth2_client_id     = string<br>  oauth2_client_secret = string<br>})</pre> | `null` | no |
| `location_id` | The location to serve the App Engine application from. This is a required field whose value cannot be changed after creation. A default value is provided for testing purposes, but it is strongly recommended to set this variable explicitly. | `string` | `"us-central"` | yes |
| `project_id` | The ID of the Google Cloud project in which to create the App Engine application. If not provided, the provider project is used. | `string` | `null` | yes |
| `standard_services` | A map of standard App Engine services to create, with one version per service definition.<br>The key of the map is the service name (e.g., 'default', 'api').<br><br>Each service object has the following attributes:<br>- `version_id`: (Optional) The ID for this version. Defaults to 'v1'.<br>- `runtime`: (Required) The runtime environment, e.g., 'python311', 'nodejs18'.<br>- `entrypoint_shell`: (Required) The command to start the application.<br>- `deployment_source_url`: (Required) The GCS URL of the zipped source code (e.g., 'gs://my-bucket/source.zip').<br>- `instance_class`: (Optional) The instance class to use (e.g., 'F1', 'B2').<br>- `env_variables`: (Optional) A map of environment variables.<br>- `inbound_services`: (Optional) A list of inbound services allowed (e.g., 'INBOUND\_SERVICE\_WARMUP').<br>- `noop_on_destroy`: (Optional) If true, prevents Terraform from deleting the version. Defaults to true.<br>- `app_engine_apis`: (Optional) Enables App Engine legacy APIs.<br>- `threadsafe`: (Optional) Whether the app can handle concurrent requests.<br>- `scaling`: (Optional) A block to configure scaling. Only one of `automatic_scaling`, `basic_scaling`, or `manual_scaling` can be defined. | `map(any)` | `{}` | no |
| `traffic_splits` | A map of traffic splitting configurations for services. The key of the map is the service name.<br><br>Each traffic split object has the following attributes:<br>- `shard_by`: (Required) The method to split traffic ('IP', 'COOKIE', or 'RANDOM').<br>- `allocations`: (Required) A map where keys are version IDs and values are the portion of traffic to allocate (e.g., `{'v1': 0.9, 'v2': 0.1}`). The sum must be 1.0. | `map(any)` | `{}` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|:---------:|
| `application_code_bucket` | The GCS bucket used for staging code for the application. | no |
| `application_default_hostname` | The default hostname for the App Engine application. | no |
| `application_id` | The ID of the App Engine application. | no |
| `application_name` | The name of the App Engine application. | no |
| `flexible_service_details` | A map containing details of the created flexible App Engine services, keyed by service name. | no |
| `standard_service_details` | A map containing details of the created standard App Engine services, keyed by service name. | no |

## Requirements

### Terraform

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.34.0 |

### APIs

A project with the following APIs enabled must be used to host the resources of this module:

-   App Engine Admin API: `appengine.googleapis.com`
