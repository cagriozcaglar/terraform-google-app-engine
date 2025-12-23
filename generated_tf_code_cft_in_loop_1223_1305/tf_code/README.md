# Google App Engine Module

This module handles the deployment of a single version for a Google App Engine service. It supports both **standard** and **flexible** environments and can optionally create the App Engine application if it doesn't exist in the project.

## Usage

This module requires a minimum set of variables to be provided to enable its resources: `project_id`, `service_name`, `version_id`, `runtime`, `deployment`, `entrypoint`, and `env_type`. If `create_app` is set to `true` (the default), `location_id` is also required.

Below is a basic example of deploying a standard environment service.

```hcl
module "app_engine_service" {
  source = "./path/to/this/module"

  project_id    = "my-gcp-project-id"
  location_id   = "us-central1" # Required because create_app is true by default.
  create_app    = true

  env_type      = "standard"
  service_name  = "my-web-app"
  version_id    = "v1-0-0"
  runtime       = "python311"
  
  entrypoint = {
    shell = "gunicorn -b :$PORT main:app"
  }
  
  deployment = {
    zip = {
      source_url = "gs://my-source-code-bucket/release-v1.0.0.zip"
    }
  }

  instance_class = "F1"
  
  standard_scaling = {
    automatic_scaling = {
      min_idle_instances = 1
      max_idle_instances = 3
    }
  }
  
  env_variables = {
    ENV_VAR_1 = "value1"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_app"></a> [create\_app](#input\_create\_app) | If true, creates the App Engine application. This is a one-time operation per project. | `bool` | `true` | no |
| <a name="input_delete_service_on_destroy"></a> [delete\_service\_on\_destroy](#input\_delete\_service\_on\_destroy) | If set to true, the service will be deleted when the app version is destroyed. (Standard environment only) | `bool` | `false` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | Deployment configuration for the app version. For a standard environment, this should be a map with a 'zip' block containing 'source\_url'. For a flexible environment, it can contain either a 'zip' block or a 'container' block with 'image'. Example for standard: { zip = { source\_url = "gs://my-bucket/my-app.zip" } }. Example for flex: { container = { image = "gcr.io/google-appengine/python-hello-world" } }. Note: When using a 'zip' deployment with 'source\_url', the deploying principal must have 'Storage Object Viewer' (roles/storage.objectViewer) permissions on the GCS bucket. | `object(...)` | `null` | yes |
| <a name="input_entrypoint"></a> [entrypoint](#input\_entrypoint) | The entrypoint for the application, which is required for all deployments. This should be a map containing a 'shell' key with the command string. Example: { shell = "gunicorn -b :$PORT main:app" } | `object({ shell = string })` | `null` | yes |
| <a name="input_env_type"></a> [env\_type](#input\_env\_type) | The App Engine environment type. Must be one of 'standard' or 'flex'. | `string` | `null` | yes |
| <a name="input_env_variables"></a> [env\_variables](#input\_env\_variables) | A map of environment variables to forward to the application. | `map(string)` | `{}` | no |
| <a name="input_flex_settings"></a> [flex\_settings](#input\_flex\_settings) | A map of settings specific to the flexible environment. The 'liveness\_check' and 'readiness\_check' blocks are required by App Engine Flex. If not specified, default check paths will be used. Can also contain optional keys for 'resources', 'network', 'automatic\_scaling', and 'vpc\_access\_connector'. | `object(...)` | `{}` | no |
| <a name="input_inbound_services"></a> [inbound\_services](#input\_inbound\_services) | A list of inbound services for the App Engine version. Allowed values are 'INBOUND\_SERVICE\_MAIL', 'INBOUND\_SERVICE\_MAIL\_BOUNCE', 'INBOUND\_SERVICE\_XMPP\_ERROR', 'INBOUND\_SERVICE\_XMPP\_MESSAGE', 'INBOUND\_SERVICE\_XMPP\_SUBSCRIBE', 'INBOUND\_SERVICE\_XMPP\_PRESENCE', 'INBOUND\_SERVICE\_CHANNEL\_PRESENCE', and 'INBOUND\_SERVICE\_WARMUP'. | `list(string)` | `null` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Instance class that is used to run this version. Valid values are F1, F2, F4, F4\_1G, B1, B2, B4, B8, B4\_1G. (Standard environment only) | `string` | `null` | no |
| <a name="input_location_id"></a> [location\_id](#input\_location\_id) | The location to serve the App Engine application from. Required if create\_app is true. | `string` | `null` | no |
| <a name="input_noop_on_destroy"></a> [noop\_on\_destroy](#input\_noop\_on\_destroy) | If set to true, the app version will not be deleted when the resource is destroyed. This is useful for managing traffic splits. | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project that the App Engine application belongs to. | `string` | `null` | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime environment for the application. For example, 'python311' or 'nodejs20'. | `string` | `null` | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The service account to be used for the application. If not provided, the App Engine default service account is used. It is recommended to use a dedicated service account with least privileges. | `string` | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the service to deploy. | `string` | `null` | yes |
| <a name="input_standard_scaling"></a> [standard\_scaling](#input\_standard\_scaling) | Scaling settings for the standard environment. This should be a map containing exactly one of the following keys: 'automatic\_scaling', 'basic\_scaling', or 'manual\_scaling'. The value should be an object with the settings for that scaling type. | `object(...)` | `{}` | no |
| <a name="input_version_id"></a> [version\_id](#input\_version\_id) | The version ID for the new deployment. | `string` | `null` | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | The full resource name of the deployed App Engine version. |
| <a name="output_service"></a> [service](#output\_service) | The name of the service the version was deployed to. |
| <a name="output_version_id"></a> [version\_id](#output\_version\_id) | The ID of the deployed version. |

## Requirements

### Terraform

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.34.0 |
