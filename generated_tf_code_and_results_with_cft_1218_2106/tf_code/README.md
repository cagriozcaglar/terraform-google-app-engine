# Terraform Google App Engine Module

This module provides a comprehensive way to manage and deploy applications to Google App Engine. It supports both the **Standard** and **Flexible** environments, handles the initial one-time setup of the App Engine application, and deploys new service versions from either a source archive or a container image. It also includes fine-grained control over scaling, health checks, networking, and traffic splitting.

This module will:
1.  Create the main App Engine Application resource for a project (a one-time operation).
2.  Deploy a new version to a service in either the Standard or Flexible environment.
3.  Configure various scaling options (Automatic, Basic, or Manual).
4.  Configure traffic splitting for canary or blue/green deployments.

## Prerequisites

Before this module can be used on a new project, you must ensure that the following APIs are enabled:

*   **App Engine Admin API**: `gcloud services enable appengine.googleapis.com`

The service account or user running Terraform will also need the following roles:
*   `roles/appengine.admin` on the project.
*   `roles/iam.serviceAccountUser` on the `service_account` if you are specifying one.

## Usage

### Basic Standard Environment Deployment

The following example creates an App Engine application and deploys a new version from a ZIP archive in Google Cloud Storage to the Standard environment.

```terraform
module "app_engine_standard" {
  source  = "GoogleCloudPlatform/app-engine/google"
  version = "~> 0.1"

  project_id       = "your-gcp-project-id"
  location_id      = "us-central"
  environment_type = "standard"
  runtime          = "python311"
  service_name     = "my-standard-service"

  deployment = {
    zip = {
      source_url = "gs://my-app-bucket/source.zip"
    }
  }

  standard_automatic_scaling = {
    max_concurrent_requests = 80
    max_instances           = 5
  }
}
```

### Basic Flexible Environment Deployment

The following example deploys a new version from a container image to the Flexible environment. Note that the App Engine application resource must have been created in a previous step (or by setting `create_app = true`).

```terraform
module "app_engine_flexible" {
  source  = "GoogleCloudPlatform/app-engine/google"
  version = "~> 0.1"

  project_id       = "your-gcp-project-id"
  location_id      = "us-central" # Must match the existing app's location
  create_app       = false        # Assumes the app already exists
  environment_type = "flexible"
  runtime          = "custom"     # 'custom' is used for container-based deployments
  service_name     = "my-flexible-service"

  deployment = {
    container = {
      image = "gcr.io/your-gcp-project-id/my-app:latest"
    }
  }

  flexible_automatic_scaling = {
    cpu_utilization = {
      target_utilization = 0.6
    }
    min_total_instances = 1
    max_total_instances = 3
  }

  network = {
    name = "default"
  }

  resources = {
    cpu       = 1
    memory_gb = 2
  }

  liveness_check = {
    path = "/liveness_check"
  }

  readiness_check = {
    path = "/readiness_check"
  }
}
```

### Deployment with Traffic Splitting

This example deploys a new version `v2` and allocates 10% of traffic to it, keeping 90% on the existing `v1`.

```terraform
module "app_engine_canary" {
  source  = "GoogleCloudPlatform/app-engine/google"
  version = "~> 0.1"

  project_id   = "your-gcp-project-id"
  location_id  = "us-central"
  create_app   = false
  runtime      = "python311"
  service_name = "my-service"
  version_id   = "v2" # Deploying a new version
  promote      = false # We will manage traffic manually with the traffic_split block

  deployment = {
    zip = {
      source_url = "gs://my-app-bucket/source-v2.zip"
    }
  }

  traffic_split = {
    shard_by = "COOKIE"
    allocations = {
      "v1" = 0.9 # 90% to existing version v1
      "v2" = 0.1 # 10% to new version v2
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_id` | The ID of the Google Cloud project where App Engine resources will be created. | `string` | `null` | yes |
| `location_id` | The location to serve the App Engine application from. This is a one-time-per-project setting. | `string` | `null` | yes |
| `runtime` | The runtime environment for the App Engine version (e.g., 'python311', 'nodejs18', 'custom' for flexible environment). | `string` | `null` | yes |
| `deployment` | Deployment source configuration. For 'standard' environment, use 'zip'. For 'flexible' environment, use 'container'. | `object({ zip = optional(object({ source_url = string })), container = optional(object({ image = string })) })` | `null` | yes |
| `service_name` | The name of the App Engine service. The default service is named 'default'. | `string` | `"default"` | no |
| `version_id` | A unique identifier for the version of the service being deployed. If not provided, a value will be generated. | `string` | `null` | no |
| `create_app` | If true, creates the `google_app_engine_application` resource. Should be true for the first deployment to a project, and can be false for subsequent deployments. | `bool` | `true` | no |
| `auth_domain` | The domain to authenticate users with using Google Accounts. Only applicable when creating the application. | `string` | `null` | no |
| `iap_config` | Identity-Aware Proxy configuration for the App Engine application. Only applicable when creating the application. This variable is sensitive. | `object({ enabled = bool, oauth2_client_id = string, oauth2_client_secret = string })` | `null` | no |
| `environment_type` | The environment for the App Engine version. Must be 'standard' or 'flexible'. | `string` | `"standard"` | no |
| `env_variables` | A map of environment variables to set for the App Engine version. | `map(string)` | `{}` | no |
| `service_account` | The service account to be used by the App Engine version. If not specified, the project's default App Engine service account is used. | `string` | `null` | no |
| `noop_on_destroy` | If set to true, the App Engine version will not be deleted when the resource is destroyed. This is useful for retaining old versions. | `bool` | `false` | no |
| `promote` | If set to true, the newly deployed version will automatically receive 100% of traffic. This behavior is overridden if `traffic_split` is specified. | `bool` | `true` | no |
| `inbound_services` | A list of inbound services that are allowed to connect to this version. (e.g., 'INBOUND\_SERVICE\_MAIL', 'INBOUND\_SERVICE\_WARMUP'). Only for standard environment. | `list(string)` | `null` | no |
| `instance_class` | The instance class to use for the standard environment (e.g., 'F1', 'B2'). | `string` | `null` | no |
| `entrypoint` | The entrypoint for the application, which specifies the command to start the app. Only for standard environment. | `object({ shell = string })` | `null` | no |
| `standard_automatic_scaling` | Configuration for automatic scaling in the standard environment. Only one of `standard_*_scaling` can be configured. | `object({ min_idle_instances = optional(number), max_idle_instances = optional(number), min_pending_latency = optional(string), max_pending_latency = optional(string), max_concurrent_requests = optional(number), standard_scheduler_settings = optional(object({ min_instances = optional(number), max_instances = optional(number), target_cpu_utilization = optional(number), target_throughput_utilization = optional(number) })) })` | `null` | no |
| `standard_basic_scaling` | Configuration for basic scaling in the standard environment. Only one of `standard_*_scaling` can be configured. | `object({ max_instances = number, idle_timeout = optional(string) })` | `null` | no |
| `standard_manual_scaling` | Configuration for manual scaling in the standard environment. Only one of `standard_*_scaling` can be configured. | `object({ instances = number })` | `null` | no |
| `flexible_automatic_scaling` | Configuration for automatic scaling in the flexible environment. Exactly one of `flexible_*_scaling` must be configured for the flexible environment. | `object({ cool_down_period = optional(string), cpu_utilization = object({ target_utilization = number }), max_total_instances = optional(number), min_total_instances = optional(number), max_concurrent_requests = optional(number), max_pending_latency = optional(string), min_pending_latency = optional(string), request_utilization = optional(object({ target_request_count_per_second = optional(number), target_concurrent_requests = optional(number) })), disk_utilization = optional(object({ target_write_bytes_per_second = optional(number), target_write_ops_per_second = optional(number), target_read_bytes_per_second = optional(number), target_read_ops_per_second = optional(number) })), network_utilization = optional(object({ target_sent_bytes_per_second = optional(number), target_sent_packets_per_second = optional(number), target_received_bytes_per_second = optional(number), target_received_packets_per_second = optional(number) })) })` | `null` | no |
| `flexible_manual_scaling` | Configuration for manual scaling in the flexible environment. Exactly one of `flexible_*_scaling` must be configured for the flexible environment. | `object({ instances = number })` | `null` | no |
| `liveness_check` | Health check configuration to detect whether an instance is running. Only for flexible environment. | `object({ path = string, check_interval = optional(string), timeout = optional(string), failure_threshold = optional(number), success_threshold = optional(number), host = optional(string), initial_delay = optional(string) })` | `null` | no |
| `readiness_check` | Health check configuration to detect whether an instance is ready to serve traffic. Only for flexible environment. | `object({ path = string, check_interval = optional(string), timeout = optional(string), failure_threshold = optional(number), success_threshold = optional(number), host = optional(string), app_start_timeout = optional(string) })` | `null` | no |
| `resources` | Machine resource configuration for the flexible environment. | `object({ cpu = number, memory_gb = number, disk_gb = optional(number), volumes = optional(list(object({ name = string, volume_type = string, size_gb = number }))) })` | `null` | no |
| `network` | Network configuration for the flexible environment. | `object({ forwarded_ports = optional(list(string)), instance_tag = optional(string), name = string, subnetwork = optional(string), session_affinity = optional(bool) })` | `null` | no |
| `traffic_split` | Configuration for splitting traffic between different versions of a service. Overrides the `promote` variable. | `object({ shard_by = string, allocations = map(number) })` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `app_engine_application_id` | The unique ID of the App Engine application. |
| `app_engine_application_url` | The default URL to access the App Engine application. |
| `service` | The name of the App Engine service where the version was deployed. |
| `version_id` | The unique identifier for the deployed version. |
| `version_name` | The full name of the deployed App Engine version. |

## Requirements

### Terraform Versions

This module has been tested with Terraform `1.0` and later.

### Providers

| Name | Version |
|------|---------|
| google | >= 4.50.0 |
