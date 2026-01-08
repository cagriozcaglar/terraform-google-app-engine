variable "project_id" {
  description = "The ID of the project in which to create the App Engine application. If not specified, the provider's project will be used."
  type        = string
  default     = null
}

variable "location_id" {
  description = "The location to serve the app from, e.g. `us-central`. Defaults to `us-central`."
  type        = string
  default     = "us-central"
}

variable "create_app" {
  description = "A boolean to control the creation of the `google_app_engine_application` resource. Set to `false` if you are only deploying services to an existing application."
  type        = bool
  default     = true
}

variable "auth_domain" {
  description = "The domain to authenticate users with when using App Engine's User API. A G Suite domain is required if IAP is enabled."
  type        = string
  default     = null
}

variable "serving_status" {
  description = "The serving status of the application. Can be `SERVING` or `USER_DISABLED`."
  type        = string
  default     = "SERVING"
}

variable "database_type" {
  description = "The type of the database to use. Can be `CLOUD_FIRESTORE` or `CLOUD_DATASTORE_COMPATIBILITY`. If not specified, it will be chosen based on the project's history."
  type        = string
  default     = null
}

variable "feature_settings" {
  description = "A map of feature settings to configure on the application."
  type = object({
    split_health_checks = bool
  })
  default = {
    split_health_checks = true
  }
}

variable "iap" {
  description = "Identity-Aware Proxy (IAP) configuration for the App Engine application. If this is block is not provided, IAP will be disabled."
  type = object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  default   = null
  sensitive = true
}

variable "services" {
  description = "A map of App Engine services to deploy. The map key is the service name (e.g., 'default', 'api')."
  type = map(object({
    split = optional(object({
      shard_by        = optional(string, "IP")
      migrate_traffic = optional(bool, false)
      allocations     = map(number)
    }), null)
    versions = map(object({
      env                       = optional(string, "standard")
      runtime                   = string
      service_account           = optional(string)
      env_variables             = optional(map(string), {})
      noop_on_destroy           = optional(bool, true)
      inbound_services          = optional(list(string))
      delete_service_on_destroy = optional(bool, false)
      deployment = object({
        zip = optional(object({
          source_url = string
        }))
        container = optional(object({
          image = string
        }))
      })
      standard = optional(object({
        entrypoint_shell  = optional(string)
        instance_class    = optional(string, "F1")
        automatic_scaling = optional(object({
          max_concurrent_requests = optional(number)
          max_idle_instances      = optional(number)
          max_pending_latency     = optional(string)
          min_idle_instances      = optional(number)
          min_pending_latency     = optional(string)
          standard_scheduler_settings = optional(object({
            max_instances                 = optional(number)
            min_instances                 = optional(number)
            target_cpu_utilization        = optional(number)
            target_throughput_utilization = optional(number)
          }), null)
        }), null)
        basic_scaling = optional(object({
          idle_timeout  = optional(string)
          max_instances = number
        }), null)
        manual_scaling = optional(object({
          instances = number
        }), null)
      }), {})
      flexible = optional(object({
        liveness_check = optional(object({
          path              = string
          check_interval    = optional(string)
          timeout           = optional(string)
          failure_threshold = optional(number)
          success_threshold = optional(number)
          host              = optional(string)
          initial_delay     = optional(string)
        }))
        readiness_check = optional(object({
          path              = string
          check_interval    = optional(string)
          timeout           = optional(string)
          failure_threshold = optional(number)
          success_threshold = optional(number)
          host              = optional(string)
          app_start_timeout = optional(string)
        }))
        resources = optional(object({
          cpu       = number
          memory_gb = number
          disk_gb   = optional(number)
        }))
        network = optional(object({
          name            = string
          instance_tag    = optional(string)
          subnetwork      = optional(string)
          forwarded_ports = optional(list(string), [])
        }))
        automatic_scaling = optional(object({
          cool_down_period        = optional(string)
          cpu_utilization         = object({ target_utilization = number })
          max_concurrent_requests = optional(number)
          max_idle_instances      = optional(number)
          max_pending_latency     = optional(string)
          max_total_instances     = optional(number)
          min_idle_instances      = optional(number)
          min_pending_latency     = optional(string)
          min_total_instances     = optional(number)
          network_utilization = optional(object({
            target_sent_bytes_per_second   = optional(number)
            target_sent_packets_per_second = optional(number)
            target_received_bytes_per_second = optional(number)
            target_received_packets_per_second = optional(number)
          }), null)
          disk_utilization = optional(object({
            target_write_bytes_per_second = optional(number)
            target_write_ops_per_second   = optional(number)
            target_read_bytes_per_second  = optional(number)
            target_read_ops_per_second    = optional(number)
          }), null)
          request_utilization = optional(object({
            target_request_count_per_second = optional(number)
            target_concurrent_requests      = optional(number)
          }), null)
        }), null)
        manual_scaling = optional(object({
          instances = number
        }), null)
      }), {})
    }))
  }))
  default  = {}
  nullable = false
}
