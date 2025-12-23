# Google Cloud App Engine Module

This module handles the deployment and configuration of a Google Cloud App Engine application. It simplifies the process of setting up the core application, deploying services for both Standard and Flexible environments, mapping custom domains, and configuring firewall rules.

## Usage

Below is a basic example of how to use this module to deploy a simple App Engine Standard service.

```hcl
module "app_engine" {
  source = "./path/to/this/module"

  project_id  = "your-gcp-project-id"
  location_id = "us-central1"

  standard_services = {
    "default-service" = {
      service_name = "default"
      runtime      = "nodejs18"
      entrypoint = {
        shell = "gunicorn -b :$PORT main:app"
      }
      deployment = {
        zip = {
          source_url = "https://storage.googleapis.com/your-bucket/source.zip"
        }
      }
      automatic_scaling = {
        max_concurrent_requests = 80
        standard_scheduler_settings = {
          min_instances = 1
          max_instances = 10
        }
      }
      env_variables = {
        FOO = "bar"
      }
    }
  }

  custom_domains = [{
    domain_name = "www.example.com"
  }]

  firewall_rules = [{
    action       = "ALLOW"
    source_range = "0.0.0.0/0"
    priority     = 2147483647
    description  = "Allow all traffic by default."
  }]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.30 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.30 |

## Resources

| Name | Type |
|------|------|
| [google_app_engine_application.app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application) | resource |
| [google_app_engine_domain_mapping.custom_domain](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_domain_mapping) | resource |
| [google_app_engine_firewall_rule.firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_firewall_rule) | resource |
| [google_app_engine_flexible_app_version.flexible](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_flexible_app_version) | resource |
| [google_app_engine_standard_app_version.standard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_standard_app_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project where the App Engine application will be created. | `string` | n/a | yes |
| <a name="input_location_id"></a> [location\_id](#input\_location\_id) | The location to serve the App Engine application from. This will be the region for the app. | `string` | n/a | yes |
| <a name="input_auth_domain"></a> [auth\_domain](#input\_auth\_domain) | The GSuite domain to associate with the application for authentication. | `string` | `null` | no |
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | A list of custom domains to map to the App Engine application. `ssl_management_type` can be `AUTOMATIC` or `MANUAL`. | <pre>list(object({<br>    domain_name         = string<br>    ssl_management_type = optional(string, "AUTOMATIC")<br>  }))</pre> | `[]` | no |
| <a name="input_database_type"></a> [database\_type](#input\_database\_type) | The type of database to use with the App Engine application. Can be `CLOUD_FIRESTORE` or `CLOUD_DATASTORE_COMPATIBILITY`. | `string` | `null` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | A list of firewall rules to apply to the App Engine application. `action` can be `ALLOW` or `DENY`. | <pre>list(object({<br>    priority     = optional(number, 1000)<br>    action       = string<br>    source_range = string<br>    description  = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_flexible_services"></a> [flexible\_services](#input\_flexible\_services) | A map of App Engine Flexible services to deploy. The key of the map is a logical name for the service version resource. The `service_account` attribute can be used to specify a user-managed service account for the instances, which will require appropriate permissions (e.g., `roles/storage.objectViewer`, `roles/logging.logWriter`). | <pre>map(object({<br>    service_name              = string<br>    version_id                = optional(string)<br>    runtime                   = string<br>    deployment = object({<br>      container = object({<br>        image = string<br>      })<br>    })<br>    liveness_check = object({<br>      path              = string<br>      check_interval    = optional(string)<br>      timeout           = optional(string)<br>      failure_threshold = optional(number)<br>      success_threshold = optional(number)<br>      initial_delay     = optional(string)<br>      host              = optional(string)<br>    })<br>    readiness_check = object({<br>      path              = string<br>      check_interval    = optional(string)<br>      timeout           = optional(string)<br>      failure_threshold = optional(number)<br>      success_threshold = optional(number)<br>      app_start_timeout = optional(string)<br>      host              = optional(string)<br>    })<br>    resources = optional(object({<br>      cpu       = number<br>      memory_gb = number<br>      disk_gb   = optional(number)<br>    }))<br>    network = optional(object({<br>      name             = string<br>      forwarded_ports  = optional(list(string))<br>      instance_tag     = optional(string)<br>      session_affinity = optional(bool)<br>    }))<br>    env_variables             = optional(map(string), {})<br>    delete_service_on_destroy = optional(bool, true)<br>    noop_on_destroy           = optional(bool, false)<br>    service_account           = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_iap"></a> [iap](#input\_iap) | Settings for Identity-Aware Proxy. If set, IAP will be configured for the application. | <pre>object({<br>    oauth2_client_id     = string<br>    oauth2_client_secret = string<br>  })</pre> | `null` | no |
| <a name="input_standard_services"></a> [standard\_services](#input\_standard\_services) | A map of App Engine Standard services to deploy. The key of the map is a logical name for the service version resource. Only one of `automatic_scaling`, `basic_scaling`, or `manual_scaling` can be configured for each service. | <pre>map(object({<br>    service_name              = string<br>    version_id                = optional(string)<br>    runtime                   = string<br>    deployment = object({<br>      zip = object({<br>        source_url = string<br>      })<br>    })<br>    entrypoint = object({<br>      shell = string<br>    })<br>    instance_class    = optional(string)<br>    automatic_scaling = optional(object({<br>      max_idle_instances      = optional(number)<br>      min_idle_instances      = optional(number)<br>      max_pending_latency     = optional(string)<br>      min_pending_latency     = optional(string)<br>      max_concurrent_requests = optional(number)<br>      standard_scheduler_settings = optional(object({<br>        min_instances = optional(number)<br>        max_instances = optional(number)<br>      }))<br>    }))<br>    basic_scaling = optional(object({<br>      idle_timeout  = string<br>      max_instances = number<br>    }))<br>    manual_scaling = optional(object({<br>      instances = number<br>    }))<br>    env_variables             = optional(map(string), {})<br>    inbound_services          = optional(list(string))<br>    delete_service_on_destroy = optional(bool, true)<br>    noop_on_destroy           = optional(bool, false)<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | The default hostname for this application. |
| <a name="output_domain_mappings"></a> [domain\_mappings](#output\_domain\_mappings) | A map of the configured custom domain mappings. |
| <a name="output_firewall_rules"></a> [firewall\_rules](#output\_firewall\_rules) | A map of the configured firewall rules. |
| <a name="output_flexible_services"></a> [flexible\_services](#output\_flexible\_services) | A map of the deployed App Engine Flexible services and their attributes. |
| <a name="output_gcr_domain"></a> [gcr\_domain](#output\_gcr\_domain) | The GCR domain used for storing managed Docker images for this app. |
| <a name="output_id"></a> [id](#output\_id) | The full resource ID of the App Engine application. |
| <a name="output_name"></a> [name](#output\_name) | The name of the App Engine application, which is the project ID. |
| <a name="output_standard_services"></a> [standard\_services](#output\_standard\_services) | A map of the deployed App Engine Standard services and their attributes. |
| <a name="output_url_dispatch_rules"></a> [url\_dispatch\_rules](#output\_url\_dispatch\_rules) | The URL dispatch rules for the application, as a list of maps. |
