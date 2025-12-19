variable "project_id" {
  description = "The ID of the Google Cloud project where App Engine resources will be created."
  type        = string
  default     = null
}

variable "location_id" {
  description = "The location to serve the App Engine application from. This is a one-time-per-project setting."
  type        = string
  default     = null
}

variable "service_name" {
  description = "The name of the App Engine service. The default service is named 'default'."
  type        = string
  default     = "default"
}

variable "version_id" {
  description = "A unique identifier for the version of the service being deployed. If not provided, a value will be generated."
  type        = string
  default     = null
}

variable "create_app" {
  description = "If true, creates the `google_app_engine_application` resource. Should be true for the first deployment to a project, and can be false for subsequent deployments."
  type        = bool
  default     = true
}

variable "auth_domain" {
  description = "The domain to authenticate users with using Google Accounts. Only applicable when creating the application."
  type        = string
  default     = null
}

variable "iap_config" {
  description = "Identity-Aware Proxy configuration for the App Engine application. Only applicable when creating the application."
  type = object({
    enabled              = bool
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  default   = null
  sensitive = true
}

variable "environment_type" {
  description = "The environment for the App Engine version. Must be 'standard' or 'flexible'."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "flexible"], var.environment_type)
    error_message = "The environment_type must be either 'standard' or 'flexible'."
  }
}

variable "runtime" {
  description = "The runtime environment for the App Engine version (e.g., 'python311', 'nodejs18', 'custom' for flexible environment)."
  type        = string
  default     = null
}

variable "deployment" {
  description = "Deployment source configuration. For 'standard' environment, use 'zip'. For 'flexible' environment, use 'container'."
  type = object({
    zip = optional(object({
      source_url = string
    }))
    container = optional(object({
      image = string
    }))
  })
  default = null
}

variable "env_variables" {
  description = "A map of environment variables to set for the App Engine version."
  type        = map(string)
  default     = {}
}

variable "service_account" {
  description = "The service account to be used by the App Engine version. If not specified, the project's default App Engine service account is used. It is recommended to create a dedicated service account with the least privileges necessary."
  type        = string
  default     = null
}

variable "noop_on_destroy" {
  description = "If set to true, the App Engine version will not be deleted when the resource is destroyed. This is useful for retaining old versions."
  type        = bool
  default     = false
}

variable "promote" {
  description = "If set to true, the newly deployed version will automatically receive 100% of traffic. This behavior is overridden if `traffic_split` is specified. If false, traffic will not be migrated to the new version, requiring a manual traffic allocation."
  type        = bool
  default     = true
}

variable "inbound_services" {
  description = "A list of inbound services that are allowed to connect to this version. (e.g., 'INBOUND_SERVICE_MAIL', 'INBOUND_SERVICE_WARMUP'). Only for standard environment."
  type        = list(string)
  default     = null
}

variable "instance_class" {
  description = "The instance class to use for the standard environment (e.g., 'F1', 'B2')."
  type        = string
  default     = null
}

variable "entrypoint" {
  description = "The entrypoint for the application, which specifies the command to start the app. Only for standard environment."
  type = object({
    shell = string
  })
  default = null
}

variable "standard_automatic_scaling" {
  description = "Configuration for automatic scaling in the standard environment."
  type = object({
    min_idle_instances          = optional(number)
    max_idle_instances          = optional(number)
    min_pending_latency         = optional(string)
    max_pending_latency         = optional(string)
    max_concurrent_requests     = optional(number)
    standard_scheduler_settings = optional(object({
      min_instances                 = optional(number)
      max_instances                 = optional(number)
      target_cpu_utilization        = optional(number)
      target_throughput_utilization = optional(number)
    }))
  })
  default = null
}

variable "standard_basic_scaling" {
  description = "Configuration for basic scaling in the standard environment."
  type = object({
    max_instances = number
    idle_timeout  = optional(string)
  })
  default = null
}

variable "standard_manual_scaling" {
  description = "Configuration for manual scaling in the standard environment."
  type = object({
    instances = number
  })
  default = null
}

variable "flexible_automatic_scaling" {
  description = "Configuration for automatic scaling in the flexible environment. One of `flexible_automatic_scaling` or `flexible_manual_scaling` must be specified for flexible environment."
  type = object({
    cool_down_period = optional(string)
    cpu_utilization = object({
      target_utilization = number
    })
    max_total_instances     = optional(number)
    min_total_instances     = optional(number)
    max_concurrent_requests = optional(number)
    max_pending_latency     = optional(string)
    min_pending_latency     = optional(string)
    request_utilization = optional(object({
      target_request_count_per_second = optional(number)
      target_concurrent_requests      = optional(number)
    }))
    disk_utilization = optional(object({
      target_write_bytes_per_second = optional(number)
      target_write_ops_per_second   = optional(number)
      target_read_bytes_per_second  = optional(number)
      target_read_ops_per_second    = optional(number)
    }))
    network_utilization = optional(object({
      target_sent_bytes_per_second       = optional(number)
      target_sent_packets_per_second     = optional(number)
      target_received_bytes_per_second   = optional(number)
      target_received_packets_per_second = optional(number)
    }))
  })
  default = null
}

variable "flexible_manual_scaling" {
  description = "Configuration for manual scaling in the flexible environment. One of `flexible_automatic_scaling` or `flexible_manual_scaling` must be specified for flexible environment."
  type = object({
    instances = number
  })
  default = null
}

variable "liveness_check" {
  description = "Health check configuration to detect whether an instance is running. Only for flexible environment."
  type = object({
    path              = string
    check_interval    = optional(string)
    timeout           = optional(string)
    failure_threshold = optional(number)
    success_threshold = optional(number)
    host              = optional(string)
    initial_delay     = optional(string)
  })
  default = null
}

variable "readiness_check" {
  description = "Health check configuration to detect whether an instance is ready to serve traffic. Only for flexible environment."
  type = object({
    path              = string
    check_interval    = optional(string)
    timeout           = optional(string)
    failure_threshold = optional(number)
    success_threshold = optional(number)
    host              = optional(string)
    app_start_timeout = optional(string)
  })
  default = null
}

variable "resources" {
  description = "Machine resource configuration for the flexible environment."
  type = object({
    cpu       = number
    memory_gb = number
    disk_gb   = optional(number)
    volumes = optional(list(object({
      name        = string
      volume_type = string
      size_gb     = number
    })))
  })
  default = null
}

variable "network" {
  description = "Network configuration for the flexible environment."
  type = object({
    forwarded_ports  = optional(list(string))
    instance_tag     = optional(string)
    name             = string
    subnetwork       = optional(string)
    session_affinity = optional(bool)
  })
  default = null
}

variable "traffic_split" {
  description = "Configuration for splitting traffic between different versions of a service."
  type = object({
    shard_by    = string
    allocations = map(number)
  })
  default = null
}
