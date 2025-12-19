# The custom domain to use for authentication.
variable "auth_domain" {
  description = "The custom domain to use for authenticating users. Leave null to use the default Google accounts domain."
  type        = string
  default     = null
}

# The type of database to use with the App Engine application.
variable "database_type" {
  description = "The type of database to use. Can be 'CLOUD_FIRESTORE' or 'CLOUD_DATASTORE_COMPATIBILITY'. Leave null to use the default."
  type        = string
  default     = null
}

# Feature settings for the App Engine application.
variable "feature_settings" {
  description = "A configuration block for feature settings of the App Engine application."
  type = object({
    split_health_checks = bool
  })
  default = {
    # If true, health checks are split between the instance and the load balancer.
    split_health_checks = true
  }
}

# A map of App Engine flexible services to be created.
variable "flexible_services" {
  description = <<-EOD
  A map of flexible App Engine services to create, with one version per service definition.
  The key of the map is the service name.

  Each service object has the following attributes:
  - `version_id`: (Optional) The ID for this version. Defaults to 'v1-flex'.
  - `runtime`: (Optional) The runtime environment. Defaults to 'custom' for containers.
  - `deployment_image_url`: (Required) The full URL of the container image to deploy.
  - `env_variables`: (Optional) A map of environment variables.
  - `noop_on_destroy`: (Optional) If true, prevents Terraform from deleting the version. Defaults to true.
  - `serving_status`: (Optional) The serving status of the version. Defaults to 'SERVING'.
  - `liveness_check`: (Optional) Configuration for liveness health checks.
  - `readiness_check`: (Optional) Configuration for readiness health checks.
  - `resources`: (Optional) Machine resource settings like `cpu`, `memory_gb`, and `disk_gb`.
  - `network`: (Optional) Network configuration for the service.
  - `automatic_scaling`: (Optional) Automatic scaling settings for the service.
  EOD
  type = map(object({
    version_id           = optional(string, "v1-flex")
    runtime              = optional(string, "custom")
    deployment_image_url = string
    runtime_api_version  = optional(string, "1")
    serving_status       = optional(string, "SERVING")
    inbound_services     = optional(list(string))
    env_variables        = optional(map(string), {})
    noop_on_destroy      = optional(bool, true)
    liveness_check = optional(object({
      path              = string
      host              = optional(string)
      timeout           = optional(string)
      check_interval    = optional(string)
      failure_threshold = optional(number)
      success_threshold = optional(number)
      initial_delay     = optional(string)
    }))
    readiness_check = optional(object({
      path              = string
      host              = optional(string)
      timeout           = optional(string)
      check_interval    = optional(string)
      failure_threshold = optional(number)
      success_threshold = optional(number)
      app_start_timeout = optional(string)
    }))
    resources = optional(object({
      cpu       = optional(number, 1)
      memory_gb = optional(number, 1)
      disk_gb   = optional(number, 10)
      volumes = optional(list(object({
        name        = string
        volume_type = string
        size_gb     = number
      })), [])
    }))
    network = optional(object({
      name             = string
      forwarded_ports  = optional(list(string), [])
      instance_tag     = optional(string)
      subnetwork       = optional(string)
      session_affinity = optional(bool)
    }))
    automatic_scaling = optional(object({
      min_total_instances = optional(number)
      max_total_instances = optional(number)
      cool_down_period    = optional(string)
      cpu_utilization = object({
        target_utilization = number
      })
    }))
  }))
  default = {}
}

# Identity-Aware Proxy (IAP) settings for the App Engine application.
variable "iap" {
  description = "Configuration for Identity-Aware Proxy (IAP). If set, IAP will be enabled for the application."
  type = object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  default   = null
  sensitive = true
}

# The location ID for the App Engine application.
variable "location_id" {
  description = "The location to serve the App Engine application from. This is a required field whose value cannot be changed after creation. A default value is provided for testing purposes, but it is strongly recommended to set this variable explicitly."
  type        = string
  default     = "us-central"
}

# The unique ID of the App Engine application.
variable "project_id" {
  description = "The ID of the Google Cloud project in which to create the App Engine application. If not provided, the provider project is used."
  type        = string
  default     = null
}

# A map of App Engine standard services to be created.
variable "standard_services" {
  description = <<-EOD
  A map of standard App Engine services to create, with one version per service definition.
  The key of the map is the service name (e.g., 'default', 'api').

  Each service object has the following attributes:
  - `version_id`: (Optional) The ID for this version. Defaults to 'v1'.
  - `runtime`: (Required) The runtime environment, e.g., 'python311', 'nodejs18'.
  - `entrypoint_shell`: (Required) The command to start the application.
  - `deployment_source_url`: (Required) The GCS URL of the zipped source code (e.g., 'gs://my-bucket/source.zip').
  - `instance_class`: (Optional) The instance class to use (e.g., 'F1', 'B2').
  - `env_variables`: (Optional) A map of environment variables.
  - `inbound_services`: (Optional) A list of inbound services allowed (e.g., 'INBOUND_SERVICE_WARMUP').
  - `noop_on_destroy`: (Optional) If true, prevents Terraform from deleting the version. Defaults to true.
  - `app_engine_apis`: (Optional) Enables App Engine legacy APIs.
  - `threadsafe`: (Optional) Whether the app can handle concurrent requests.
  - `scaling`: (Optional) A block to configure scaling. Only one of `automatic_scaling`, `basic_scaling`, or `manual_scaling` can be defined.
    - `automatic_scaling`: Configures automatic scaling with settings like `min_idle_instances`, `max_instances`, etc.
    - `basic_scaling`: Configures basic scaling with `max_instances` and `idle_timeout`.
    - `manual_scaling`: Configures manual scaling with a fixed number of `instances`.
  EOD
  type = map(object({
    version_id            = optional(string, "v1")
    runtime               = string
    entrypoint_shell      = string
    deployment_source_url = string
    instance_class        = optional(string)
    env_variables         = optional(map(string), {})
    inbound_services      = optional(list(string))
    noop_on_destroy       = optional(bool, true)
    app_engine_apis       = optional(bool)
    threadsafe            = optional(bool)
    scaling = optional(object({
      automatic_scaling = optional(object({
        max_concurrent_requests   = optional(number)
        min_idle_instances        = optional(number)
        max_idle_instances        = optional(number)
        min_pending_latency       = optional(string)
        max_pending_latency       = optional(string)
        standard_scheduler_settings = object({
          target_cpu_utilization        = optional(number)
          target_throughput_utilization = optional(number)
          min_instances                 = optional(number)
          max_instances                 = optional(number)
        })
      }))
      basic_scaling = optional(object({
        max_instances = number
        idle_timeout  = optional(string)
      }))
      manual_scaling = optional(object({
        instances = number
      }))
    }))
  }))
  default = {}
}

# A map of traffic splitting configurations for App Engine services.
variable "traffic_splits" {
  description = <<-EOD
  A map of traffic splitting configurations for services. The key of the map is the service name.

  Each traffic split object has the following attributes:
  - `shard_by`: (Required) The method to split traffic ('IP', 'COOKIE', or 'RANDOM').
  - `allocations`: (Required) A map where keys are version IDs and values are the portion of traffic to allocate (e.g., `{'v1': 0.9, 'v2': 0.1}`). The sum must be 1.0.
  EOD
  type = map(object({
    shard_by    = string
    allocations = map(number)
  }))
  default = {}
}
