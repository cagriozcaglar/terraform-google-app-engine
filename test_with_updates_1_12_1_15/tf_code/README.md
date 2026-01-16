# Google App Engine Module

This module manages a Google App Engine application, including its services, versions, traffic splitting, and domain mappings. It is designed to deploy applications from a source archive in Google Cloud Storage.

## Usage

Here is a basic example of how to use this module to deploy a default service to App Engine with a custom domain.

```hcl
module "app_engine" {
  source  = "path/to/this/module"

  project_id  = "your-gcp-project-id"
  location_id = "us-central"

  services = {
    "default" = {
      version_id = "v1-0-0"
      runtime    = "python39"
      entrypoint = {
        shell = "gunicorn -b :$PORT main:app"
      }
      deployment = {
        zip = {
          source_url = "gs://your-source-bucket/default-service-v1.zip"
        }
      }
      automatic_scaling = {
        max_concurrent_requests = 80
        min_instances           = 1
        max_instances           = 10
      }
      traffic_split = {
        allocations = {
          "v1-0-0" = 1.0
        }
      }
    }
  }

  domain_mappings = [
    {
      domain_name = "www.example.com"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.50.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.50.0 |

## Resources

| Name | Type |
|------|------|
| [google_app_engine_application.app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application) | resource |
| [google_app_engine_domain_mapping.domains](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_domain_mapping) | resource |
| [google_app_engine_service_split_traffic.split](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_service_split_traffic) | resource |
| [google_app_engine_standard_app_version.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_standard_app_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_app"></a> [create\_app](#input\_create\_app) | If true, the `google_app_engine_application` resource will be created. Set to false if you are importing an existing App Engine application or managing it outside of this module. | `bool` | `true` | no |
| <a name="input_database_type"></a> [database\_type](#input\_database\_type) | The type of database to use with the App Engine application. Can be CLOUD\_DATASTORE\_COMPATIBILITY or CLOUD\_FIRESTORE\_NATIVE. | `string` | `"CLOUD_DATASTORE_COMPATIBILITY"` | no |
| <a name="input_domain_mappings"></a> [domain\_mappings](#input\_domain\_mappings) | A list of custom domain mappings for the App Engine application. | <pre>list(object({<br>    domain_name         = string<br>    ssl_management_type = optional(string, "AUTOMATIC")<br>    certificate_id      = optional(string, null)<br>  }))</pre> | `[]` | no |
| <a name="input_location_id"></a> [location\_id](#input\_location\_id) | The location to serve the App Engine application from, e.g., `us-central`. | `string` | `"us-central"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project where the App Engine application will be created. If not provided, the provider project is used. | `string` | `null` | no |
| <a name="input_services"></a> [services](#input\_services) | A map of App Engine services to deploy. The key is the service name (e.g., 'default', 'api'). Each service object defines a single version to be deployed. | <pre>map(object({<br>    version_id      = string<br>    runtime         = string<br>    noop_on_destroy = optional(bool, false)<br>    inbound_services = optional(list(string), [<br>      "INBOUND_SERVICE_ALL",<br>    ])<br>    instance_class = optional(string, "F1")<br>    env_variables  = optional(map(string), {})<br>    deployment = object({<br>      zip = object({<br>        source_url = string<br>      })<br>    })<br>    entrypoint = object({<br>      shell = string<br>    })<br>    automatic_scaling = optional(object({<br>      min_idle_instances          = optional(number)<br>      max_idle_instances          = optional(number)<br>      min_pending_latency         = optional(string)<br>      max_pending_latency         = optional(string)<br>      min_instances               = optional(number)<br>      max_instances               = optional(number)<br>      target_cpu_utilization      = optional(number)<br>      target_throughput_utilization = optional(number)<br>      max_concurrent_requests     = optional(number)<br>    }), null)<br>    basic_scaling = optional(object({<br>      max_instances = number<br>      idle_timeout  = optional(string)<br>    }), null)<br>    manual_scaling = optional(object({<br>      instances = number<br>    }), null)<br>    traffic_split = optional(object({<br>      migrate_traffic = optional(bool, false)<br>      shard_by        = optional(string, "IP")<br>      allocations     = map(number)<br>    }), null)<br>  }))</pre> | `{}` | no |
| <a name="input_serving_status"></a> [serving\_status](#input\_serving\_status) | The serving status of the application. Can be SERVING or USER\_DISABLED. | `string` | `"SERVING"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_engine_application"></a> [app\_engine\_application](#output\_app\_engine\_application) | The full App Engine application resource object. This output is empty if `create_app` is false. |
| <a name="output_app_engine_application_id"></a> [app\_engine\_application\_id](#output\_app\_engine\_application\_id) | The globally unique identifier for the App Engine application. |
| <a name="output_domain_mappings"></a> [domain\_mappings](#output\_domain\_mappings) | A map of the created domain mappings, keyed by the domain name. |
| <a name="output_services"></a> [services](#output\_services) | A map of the deployed App Engine service versions, keyed by their service name. |
