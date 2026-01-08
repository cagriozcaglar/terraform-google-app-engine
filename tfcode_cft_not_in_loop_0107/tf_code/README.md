# Terraform Google App Engine Module

This module handles the deployment and configuration of a Google App Engine application, its services, and versions. It supports both Standard and Flexible environments, advanced traffic splitting, and Identity-Aware Proxy (IAP) configuration.

## Usage

Below is a basic example of how to use this module to create an App Engine application and deploy a single "default" service with one version.

```terraform
module "app_engine_app" {
  source = "./" // Or a path to the module

  project_id  = "your-gcp-project-id"
  location_id = "us-central"

  // Enable IAP for the application
  iap = {
    oauth2_client_id     = "YOUR_OAUTH2_CLIENT_ID.apps.googleusercontent.com"
    oauth2_client_secret = "YOUR_OAUTH2_CLIENT_SECRET"
  }

  // Define services and their versions
  services = {
    "default" = {
      // Configure traffic splitting for the 'default' service
      split = {
        allocations = {
          "v1" = 1.0
        }
      }

      // Define versions for the 'default' service
      versions = {
        "v1" = {
          env     = "standard"
          runtime = "python39"

          // Deploy from a source zip in a GCS bucket
          deployment = {
            zip = {
              source_url = "gs://my-app-source-bucket/v1.zip"
            }
          }

          // Configure scaling for the standard environment
          standard = {
            instance_class = "F2"
            automatic_scaling = {
              max_instances = 2
              min_instances = 1
            }
          }
        }
      }
    }
  }
}
```

## Requirements

Before this module can be used on a project, you must ensure that the following APIs are enabled on the target project:
- App Engine Admin API: `appengine.googleapis.com`

The module requires the following:
- Terraform v1.3+
- Terraform Provider for GCP v4.34.0+

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| auth\_domain | The domain to authenticate users with when using App Engine's User API. A G Suite domain is required if IAP is enabled. | `string` | `null` | no |
| create\_app | A boolean to control the creation of the `google_app_engine_application` resource. Set to `false` if you are only deploying services to an existing application. | `bool` | `true` | no |
| database\_type | The type of the database to use. Can be `CLOUD_FIRESTORE` or `CLOUD_DATASTORE_COMPATIBILITY`. If not specified, it will be chosen based on the project's history. | `string` | `null` | no |
| feature\_settings | A map of feature settings to configure on the application. | <pre>object({<br>  split_health_checks = bool<br>})</pre> | `{ split_health_checks: true }` | no |
| iap | Identity-Aware Proxy (IAP) configuration for the App Engine application. If this is block is not provided, IAP will be disabled. This variable is sensitive. | <pre>object({<br>  oauth2_client_id     = string<br>  oauth2_client_secret = string<br>})</pre> | `null` | no |
| location\_id | The location to serve the app from, e.g. `us-central`. | `string` | `"us-central"` | no |
| project\_id | The ID of the project in which to create the App Engine application. If not specified, the provider's project will be used. | `string` | `null` | no |
| services | A map of App Engine services to deploy. The map key is the service name (e.g., 'default', 'api').<br><br>The structure for each service object is:<br><ul><li>`split` (Optional): Configures traffic splitting for the service.<ul><li>`shard_by` (Optional): Method to split traffic. Defaults to `IP`.</li><li>`migrate_traffic` (Optional): Whether to gradually migrate traffic. Defaults to `false`.</li><li>`allocations`: A map of version IDs to traffic allocation percentages (e.g., `{ "v1": 1.0 }`).</li></ul></li><li>`versions`: A map of versions to deploy for the service. The key is the version ID (e.g., 'v1', 'green').<ul><li>`env` (Optional): The environment ('standard' or 'flexible'). Defaults to `standard`.</li><li>`runtime`: The runtime identifier (e.g., `python39`, `custom`).</li><li>`service_account` (Optional): The service account for the version.</li><li>`env_variables` (Optional): A map of environment variables.</li><li>`deployment`: The code deployment configuration. Must define either `zip` (for standard) or `container` (for flexible).</li><li>`standard` (Optional): Configuration specific to the Standard environment (e.g., `instance_class`, `automatic_scaling`, `basic_scaling`).</li><li>`flexible` (Optional): Configuration specific to the Flexible environment (e.g., `liveness_check`, `readiness_check`, `resources`, `network`).</li></ul></li></ul> | `map(any)` | `{}` | no |
| serving\_status | The serving status of the application. Can be `SERVING` or `USER_DISABLED`. | `string` | `"SERVING"` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_gcr\_domain | The GCR domain used for storing instance images. |
| app\_id | The globally unique identifier for the App Engine application. |
| app\_url | The default URL to access the App Engine application. |
| flexible\_versions | A map of the deployed App Engine flexible versions. |
| service\_urls | A map of service names to their default URLs. This is only populated if `create_app` is true. |
| standard\_versions | A map of the deployed App Engine standard versions. |
