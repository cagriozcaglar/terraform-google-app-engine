# Terraform Google App Engine Standard Module

This module handles the deployment of a Google Cloud App Engine standard environment application. It can create the App Engine application itself (a one-time operation per project), deploy a new version from a source ZIP file in Google Cloud Storage, and configure various settings like scaling, environment variables, and traffic splitting.

## Usage

Here is a basic example of how to use the module:

```hcl
module "app_engine_standard" {
  source = "./" // Or a Git URL to the module

  project_id                  = "your-gcp-project-id"
  location_id                 = "us-central"
  deployment_zip_source_url   = "gs://your-source-code-bucket/app.zip"

  service_name                = "my-web-app"
  version_id                  = "v1-0-0"
  runtime                     = "python311"
  entrypoint_shell            = "gunicorn -b :$PORT main:app"
  instance_class              = "F2"

  env_variables = {
    DATABASE_URL = "your-database-connection-string"
    SECRET_KEY   = "super-secret"
  }

  automatic_scaling = {
    min_idle_instances  = 0
    max_idle_instances  = 2
    max_instances       = 5
    max_pending_latency = "50ms"
  }
}
```

To configure traffic splitting between versions, you can use the `traffic_split` variable:

```hcl
module "app_engine_standard_v2" {
  source = "./"

  project_id                  = "your-gcp-project-id"
  location_id                 = "us-central"
  deployment_zip_source_url   = "gs://your-source-code-bucket/app-v2.zip"
  create_app                  = false // App already exists

  service_name                = "my-web-app"
  version_id                  = "v2-canary"
  // ... other variables
}

module "app_engine_traffic_split" {
  source = "./"

  # Disable version creation in this instance of the module
  project_id                  = "your-gcp-project-id"
  location_id                 = "us-central"
  deployment_zip_source_url   = null 

  service_name = "my-web-app"

  traffic_split = {
    allocations = {
      "v1-0-0"    = 0.9
      "v2-canary" = 0.1
    }
    shard_by = "IP"
  }

  depends_on = [
    module.app_engine_standard,
    module.app_engine_standard_v2
  ]
}
```

## Requirements

The following requirements are needed by this module:

- Terraform >= 1.0
- Terraform Provider for Google Cloud Platform ~> 5.0

### APIs

A project with the following APIs enabled is required:

- App Engine Admin API: `appengine.googleapis.com`

The Service Account running Terraform will require permissions to administer App Engine.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-------:|:--------:|
| `project_id` | The ID of the Google Cloud project where the App Engine application will be created and deployed. | `string` | `null` | yes |
| `location_id` | The location to serve the App Engine application from. See https://cloud.google.com/appengine/docs/locations. | `string` | `null` | yes |
| `deployment_zip_source_url` | The Google Cloud Storage URL of the zip file containing the application source code. | `string` | `null` | yes |
| `create_app` | A boolean flag to control the creation of the `google_app_engine_application` resource. Set to `false` if an App Engine application already exists in the project. | `bool` | `true` | no |
| `database_type` | The type of database to use with App Engine. Can be 'CLOUD\_FIRESTORE' or 'CLOUD\_DATASTORE\_COMPATIBILITY'. | `string` | `null` | no |
| `auth_domain` | The domain to authenticate users with when using Google Accounts API. | `string` | `null` | no |
| `service_name` | The name of the App Engine service to deploy. The 'default' service is created if not specified. | `string` | `"default"` | no |
| `version_id` | A unique identifier for the version of the service. | `string` | `"v1"` | no |
| `runtime` | The runtime environment for the application, e.g., 'python311', 'go119', 'nodejs18'. | `string` | `"python311"` | no |
| `entrypoint_shell` | The shell command to execute to start the application. | `string` | `"gunicorn -b :$PORT main:app"` | no |
| `env_variables` | A map of environment variables to be made available to the application. | `map(string)` | `{}` | no |
| `inbound_services` | A list of inbound services that can send traffic to this version. If empty or null, all traffic is allowed. See https://cloud.google.com/appengine/docs/standard/go/config/appref for valid values. | `list(string)` | `null` | no |
| `instance_class` | The instance class to use for this version. See https://cloud.google.com/appengine/docs/standard#instance\_classes for valid values. | `string` | `"F1"` | no |
| `scaling_type` | The type of scaling to use for this version. Must be one of 'automatic', 'basic', or 'manual'. | `string` | `"automatic"` | no |
| `automatic_scaling` | Configuration for automatic scaling. Used when `scaling_type` is 'automatic'. See `google_app_engine_standard_app_version` resource for available fields. | `any` | <pre>{<br>  min_idle_instances  = 1<br>  max_idle_instances  = 3<br>  max_instances       = 10<br>  max_pending_latency = "30ms"<br>}</pre> | no |
| `basic_scaling` | Configuration for basic scaling. Used when `scaling_type` is 'basic'. See `google_app_engine_standard_app_version` resource for available fields. | `any` | `null` | no |
| `manual_scaling` | Configuration for manual scaling. Used when `scaling_type` is 'manual'. See `google_app_engine_standard_app_version` resource for available fields. | `any` | `null` | no |
| `delete_service_on_destroy` | If set to true, the service will be deleted when the last version is deleted. | `bool` | `false` | no |
| `noop_on_destroy` | If set to true, Terraform will not delete the version on destroy, but will remove it from the state. | `bool` | `false` | no |
| `traffic_split` | A map defining the traffic split for the service. If set, a `google_app_engine_service_split_traffic` resource will be created. Example: `{ allocations = { "v1" = 0.9, "v2-canary" = 0.1 }, shard_by = "IP" }`. | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `app_engine_application_id` | The unique ID of the App Engine application. |
| `app_engine_application_url` | The default URL of the App Engine application. |
| `service_name` | The name of the deployed App Engine service. |
| `version_id` | The ID of the deployed App Engine version. |
| `version_name` | The full resource name of the deployed App Engine version. |
