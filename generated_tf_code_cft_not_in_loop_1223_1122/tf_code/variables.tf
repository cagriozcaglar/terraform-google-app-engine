variable "project_id" {
  description = "The ID of the Google Cloud project where the App Engine application will be created."
  type        = string
}

variable "location_id" {
  description = "The location to serve the App Engine application from. This will be the region for the app."
  type        = string
}

variable "database_type" {
  description = "The type of database to use with the App Engine application. Can be 'CLOUD_FIRESTORE' or 'CLOUD_DATASTORE_COMPATIBILITY'."
  type        = string
  default     = null
}

variable "auth_domain" {
  description = "The GSuite domain to associate with the application for authentication."
  type        = string
  default     = null
}

variable "iap" {
  description = "Settings for Identity-Aware Proxy. If set, IAP will be configured for the application."
  type = object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  default   = null
  sensitive = true
}

variable "standard_services" {
  description = "A map of App Engine Standard services to deploy. The key of the map is a logical name for the service version resource. Only one of 'automatic_scaling', 'basic_scaling', or 'manual_scaling' can be configured for each service."
  type = map(object({
    service_name              = string
    version_id                = optional(string)
    runtime                   = string
    deployment = object({
      zip = object({
        source_url = string
      })
    })
    entrypoint = object({
      shell = string
    })
    instance_class    = optional(string)
    automatic_scaling = optional(object({
      max_idle_instances      = optional(number)
      min_idle_instances      = optional(number)
      max_pending_latency     = optional(string)
      min_pending_latency     = optional(string)
      max_concurrent_requests = optional(number)
      standard_scheduler_settings = optional(object({
        min_instances = optional(number)
        max_instances = optional(number)
      }))
    }))
    basic_scaling = optional(object({
      idle_timeout  = string
      max_instances = number
    }))
    manual_scaling = optional(object({
      instances = number
    }))
    env_variables             = optional(map(string), {})
    inbound_services          = optional(list(string))
    delete_service_on_destroy = optional(bool, true)
    noop_on_destroy           = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in values(var.standard_services) : (s.automatic_scaling != null ? 1 : 0) + (s.basic_scaling != null ? 1 : 0) + (s.manual_scaling != null ? 1 : 0) <= 1
    ])
    error_message = "Only one of 'automatic_scaling', 'basic_scaling', or 'manual_scaling' can be configured for each standard service."
  }
}

variable "flexible_services" {
  description = "A map of App Engine Flexible services to deploy. The key of the map is a logical name for the service version resource. The `service_account` attribute can be used to specify a user-managed service account for the instances, which will require appropriate permissions (e.g., `roles/storage.objectViewer`, `roles/logging.logWriter`)."
  type = map(object({
    service_name              = string
    version_id                = optional(string)
    runtime                   = string
    deployment = object({
      container = object({
        image = string
      })
    })
    liveness_check = object({
      path              = string
      check_interval    = optional(string)
      timeout           = optional(string)
      failure_threshold = optional(number)
      success_threshold = optional(number)
      initial_delay     = optional(string)
      host              = optional(string)
    })
    readiness_check = object({
      path              = string
      check_interval    = optional(string)
      timeout           = optional(string)
      failure_threshold = optional(number)
      success_threshold = optional(number)
      app_start_timeout = optional(string)
      host              = optional(string)
    })
    resources = optional(object({
      cpu       = number
      memory_gb = number
      disk_gb   = optional(number)
    }))
    network = optional(object({
      name             = string
      forwarded_ports  = optional(list(string))
      instance_tag     = optional(string)
      session_affinity = optional(bool)
    }))
    env_variables             = optional(map(string), {})
    delete_service_on_destroy = optional(bool, true)
    noop_on_destroy           = optional(bool, false)
    service_account           = optional(string)
  }))
  default = {}
}

variable "custom_domains" {
  description = "A list of custom domains to map to the App Engine application."
  type = list(object({
    domain_name         = string
    ssl_management_type = optional(string, "AUTOMATIC")
  }))
  default = []
}

variable "firewall_rules" {
  description = "A list of firewall rules to apply to the App Engine application."
  type = list(object({
    priority     = optional(number, 1000)
    action       = string
    source_range = string
    description  = optional(string)
  }))
  default = []
}
