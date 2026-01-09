# Google Cloud App Engine Module

This Terraform module simplifies the deployment and management of Google App Engine applications. It supports both Standard and Flexible environments and provides a comprehensive set of configurations for services, versions, scaling, traffic splitting, and more. The module can be used to provision an App Engine application, deploy a new version, or manage traffic between existing versions.

## Prerequisites

Before you can use this module, you must ensure the following APIs are enabled on your project:

-   **App Engine Admin API**: `appengine.googleapis.com`

You can enable the API by running the following command:
```bash
gcloud services enable appengine.googleapis.com
```

## Usage

Below are examples of how to use the module for different scenarios.

### Standard Environment

This example deploys a new version to the App Engine Standard environment from a ZIP file in a GCS bucket.

```hcl
module "app_engine_standard" {
  source  = "./" // Replace with the actual module source

  project_id      = "your-gcp-project-id"
  location_id     = "us-central"
  service_name    = "my-standard-service"
  version_id      = "v1"
  env_type        = "standard"
  runtime         = "python39"
  instance_class  = "F2"
  service_account = "my-app-sa@your-gcp-project-id.iam.gserviceaccount.com"

  entrypoint = {
    shell = "gunicorn -b :$PORT main:app"
  }

  deployment_source = {
    zip = {
      source_url = "https://storage.googleapis.com/my-bucket/my-app-v1.zip"
    }
  }

  automatic_scaling = {
    max_concurrent_requests = 80
    min_idle_instances      = 1
    max_idle_instances      = 5
    standard_scheduler_settings = {
      min_instances = 1
      max_instances = 10
    }
  }

  env_variables = {
    ENV_VAR_1 = "value1"
    ENV_VAR_2 = "value2"
  }
}
```

### Flexible Environment

This example deploys a new version to the App Engine Flexible environment using a container image.

```hcl
module "app_engine_flexible" {
  source  = "./" // Replace with the actual module source

  project_id      = "your-gcp-project-id"
  location_id     = "us-central"
  service_name    = "my-flex-service"
  version_id      = "v1"
  env_type        = "flexible"
  service_account = "my-app-sa@your-gcp-project-id.iam.gserviceaccount.com"

  deployment_source = {
    container = {
      image = "gcr.io/your-gcp-project-id/my-app:latest"
    }
  }

  automatic_scaling = {
    min_total_instances = 1
    max_total_instances = 5
    cool_down_period    = "120s"
    cpu_utilization = {
      target_utilization = 0.75
    }
  }

  network = {
    name = "default"
  }

  health_check = {
    liveness_check = {
      path = "/liveness_check"
    }
    readiness_check = {
      path = "/readiness_check"
    }
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.20 |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | `null` |
| <a name="input_location_id"></a> [location\_id](#input\_location\_id) | The location to deploy the App Engine application. | `string` | `null` |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the App Engine service. | `string` | `"default"` |
| <a name="input_version_id"></a> [version\_id](#input\_version\_id) | A unique identifier for the version. | `string` | `null` |
| <a name="input_env_type"></a> [env\_type](#input\_env\_type) | The type of App Engine environment. Must be either 'standard' or 'flexible'. | `string` | `null` |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime environment for the application. Required for 'standard' env\_type. For the flexible environment, this is ignored and 'custom' is used, as only container-based deployments are supported. | `string` | `null` |
| <a name="input_deployment_source"></a> [deployment\_source](#input\_deployment\_source) | Configuration for the deployment source. Specify either 'zip' for Standard or 'container' for Flexible environment. | `object` | <pre>{<br>  zip       = null<br>  container = null<br>}</pre> |
| <a name="input_entrypoint"></a> [entrypoint](#input\_entrypoint) | The entrypoint for the application, which is required for non-container deployments in Standard environment. E.g., 'gunicorn -b :$PORT main:app'. | `object` | `null` |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance class to use for a Standard environment. If not specified, the default will be used. | `string` | `null` |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The service account to be used by the application. | `string` | `null` |
| <a name="input_create_sa_user_role"></a> [create\_sa\_user\_role](#input\_create\_sa\_user\_role) | If true and a 'service\_account' is provided, grants the App Engine service agent 'roles/iam.serviceAccountUser' on the specified service account. This allows the App Engine service to act as the specified service account. | `bool` | `true` |
| <a name="input_env_variables"></a> [env\_variables](#input\_env\_variables) | A map of environment variables to set for the application. | `map(string)` | `{}` |
| <a name="input_automatic_scaling"></a> [automatic\_scaling](#input\_automatic\_scaling) | Configuration for automatic scaling. Leave null to disable.<br>Structure differs for Standard and Flexible environments.<br>For Standard, the structure is:<br><pre>{<br>  max_concurrent_requests = number<br>  min_idle_instances      = number<br>  max_idle_instances      = number<br>  min_pending_latency     = string # e.g. "0.5s"<br>  max_pending_latency     = string # e.g. "10s"<br>  standard_scheduler_settings = {<br>    min_instances = number<br>    max_instances = number<br>  }<br>}</pre>For Flexible, the structure is:<br><pre>{<br>  min_total_instances = number<br>  max_total_instances = number<br>  cool_down_period    = string # e.g. "120s"<br>  cpu_utilization = {<br>    target_utilization = number # e.g. 0.75<br>  }<br>}</pre> | `any` | `null` |
| <a name="input_basic_scaling"></a> [basic\_scaling](#input\_basic\_scaling) | Configuration for basic scaling (Standard environment only). Leave null to disable. | `object` | `null` |
| <a name="input_manual_scaling"></a> [manual\_scaling](#input\_manual\_scaling) | Configuration for manual scaling (Standard environment only). Leave null to disable. | `object` | `null` |
| <a name="input_network"></a> [network](#input\_network) | Network settings for a Flexible environment. Leave null to use default. | `object` | `null` |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | Health check configuration for a Flexible environment. Contains 'liveness\_check' and 'readiness\_check'. | `object` | `null` |
| <a name="input_noop_on_destroy"></a> [noop\_on\_destroy](#input\_noop\_on\_destroy) | If set to true, the application version will not be deleted when the resource is destroyed and traffic will not be migrated to it automatically. This is useful for canary deployments. | `bool` | `false` |
| <a name="input_traffic_split"></a> [traffic\_split](#input\_traffic\_split) | A map of version IDs to traffic allocation percentages. The keys are version IDs and values are fractional allocations. The sum of values must be 1.0. If set, creates a traffic split configuration. | `map(number)` | `null` |
| <a name="input_migrate_traffic"></a> [migrate\_traffic](#input\_migrate\_traffic) | Whether to migrate traffic gradually. If false, traffic is switched instantly. Only applicable if 'traffic\_split' is set. | `bool` | `false` |
| <a name="input_inbound_services"></a> [inbound\_services](#input\_inbound\_services) | A list of inbound services for the application. Can be 'INBOUND\_SERVICE\_MAIL', 'INBOUND\_SERVICE\_MAIL\_BOUNCE', 'INBOUND\_SERVICE\_XMPP\_ERROR', 'INBOUND\_SERVICE\_XMPP\_MESSAGE', 'INBOUND\_SERVICE\_XMPP\_SUBSCRIBE', 'INBOUND\_SERVICE\_XMPP\_PRESENCE', 'INBOUND\_SERVICE\_CHANNEL\_PRESENCE', 'INBOUND\_SERVICE\_WARMUP'. | `list(string)` | `[]` |
| <a name="input_delete_service_on_destroy"></a> [delete\_service\_on\_destroy](#input\_delete\_service\_on\_destroy) | If set to true, the service will be deleted when all versions are removed. | `bool` | `false` |
| <a name="input_database_type"></a> [database\_type](#input\_database\_type) | The type of database to use with App Engine. Can be 'CLOUD\_FIRESTORE' or 'CLOUD\_DATASTORE\_COMPATIBILITY'. | `string` | `"CLOUD_FIRESTORE"` |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_engine_application_name"></a> [app\_engine\_application\_name](#output\_app\_engine\_application\_name) | The name of the App Engine application. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the App Engine service. |
| <a name="output_version_id"></a> [version\_id](#output\_version\_id) | The ID of the deployed App Engine version. |
| <a name="output_version_url"></a> [version\_url](#output\_version\_url) | The URL to access the deployed version. |

## Resources

| Name | Type |
|------|------|
| [google\_app\_engine\_application.app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application) | resource |
| [google\_app\_engine\_flexible\_app\_version.flexible](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_flexible_app_version) | resource |
| [google\_app\_engine\_service\_split\_traffic.split](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_service_split_traffic) | resource |
| [google\_app\_engine\_standard\_app\_version.standard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_standard_app_version) | resource |
| [google\_service\_account\_iam\_member.app\_engine\_sa\_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google\_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
