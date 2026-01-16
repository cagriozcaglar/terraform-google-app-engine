# This file contains the input variable definitions for the Terraform module.
variable "project_id" {
  description = "The ID of the Google Cloud project where the App Engine application will be created. If not provided, the provider project is used."
  type        = string
  default     = null
}

variable "location_id" {
  description = "The location to serve the App Engine application from, e.g., `us-central`."
  type        = string
  default     = "us-central"
}

variable "create_app" {
  description = "If true, the `google_app_engine_application` resource will be created. Set to false if you are importing an existing App Engine application or managing it outside of this module."
  type        = bool
  default     = true
}

variable "database_type" {
  description = "The type of database to use with the App Engine application. Can be CLOUD_DATASTORE_COMPATIBILITY or CLOUD_FIRESTORE_NATIVE."
  type        = string
  default     = "CLOUD_DATASTORE_COMPATIBILITY"
}

variable "serving_status" {
  description = "The serving status of the application. Can be SERVING or USER_DISABLED."
  type        = string
  default     = "SERVING"
}

variable "services" {
  description = "A map of App Engine services to deploy. The key is the service name (e.g., 'default', 'api'). Each service object defines a single version to be deployed."
  type = map(object({
    # --- General ---
    version_id      = string
    runtime         = string
    noop_on_destroy = optional(bool, false)
    inbound_services = optional(list(string), [
      "INBOUND_SERVICE_ALL",
    ])
    instance_class = optional(string, "F1")
    env_variables  = optional(map(string), {})
    # --- Deployment ---
    deployment = object({
      zip = object({
        source_url = string
      })
    })
    # --- Entrypoint ---
    entrypoint = object({
      shell = string
    })
    # --- Scaling (Choose one) ---
    automatic_scaling = optional(object({
      min_idle_instances          = optional(number)
      max_idle_instances          = optional(number)
      min_pending_latency         = optional(string)
      max_pending_latency         = optional(string)
      min_instances               = optional(number)
      max_instances               = optional(number)
      target_cpu_utilization      = optional(number)
      target_throughput_utilization = optional(number)
      max_concurrent_requests     = optional(number)
    }), null)
    basic_scaling = optional(object({
      max_instances = number
      idle_timeout  = optional(string)
    }), null)
    manual_scaling = optional(object({
      instances = number
    }), null)
    # --- Traffic Splitting ---
    traffic_split = optional(object({
      migrate_traffic = optional(bool, false)
      shard_by        = optional(string, "IP")
      allocations     = map(number)
    }), null)
  }))
  default     = {}
  nullable    = false
}

variable "domain_mappings" {
  description = "A list of custom domain mappings for the App Engine application."
  type = list(object({
    domain_name         = string
    ssl_management_type = optional(string, "AUTOMATIC")
    certificate_id      = optional(string, null)
  }))
  default  = []
  nullable = false
}
