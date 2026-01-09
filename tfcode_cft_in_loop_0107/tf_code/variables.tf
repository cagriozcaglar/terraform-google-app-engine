# BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK
# END OF PRE-COMMIT-TERRAFORM DOCS HOOK

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
  default     = null
}

variable "location_id" {
  description = "The location to deploy the App Engine application."
  type        = string
  default     = null
}

variable "service_name" {
  description = "The name of the App Engine service."
  type        = string
  default     = "default"
}

variable "version_id" {
  description = "A unique identifier for the version."
  type        = string
  default     = null
}

variable "env_type" {
  description = "The type of App Engine environment. Must be either 'standard' or 'flexible'."
  type        = string
  default     = null

  validation {
    condition     = var.env_type == null ? true : contains(["standard", "flexible"], var.env_type)
    error_message = "The env_type must be either 'standard' or 'flexible'."
  }
}

variable "runtime" {
  description = "The runtime environment for the application. Required for 'standard' env_type. For the flexible environment, this is ignored and 'custom' is used, as only container-based deployments are supported."
  type        = string
  default     = null
}

variable "deployment_source" {
  description = "Configuration for the deployment source. Specify either 'zip' for Standard or 'container' for Flexible environment."
  type = object({
    zip = optional(object({
      source_url = string
    }))
    container = optional(object({
      image = string
    }))
  })
  default = {
    zip       = null
    container = null
  }
}

variable "entrypoint" {
  description = "The entrypoint for the application, which is required for non-container deployments in Standard environment. E.g., 'gunicorn -b :$PORT main:app'."
  type = object({
    shell = string
  })
  default = null
}

variable "instance_class" {
  description = "The instance class to use for a Standard environment. If not specified, the default will be used."
  type        = string
  default     = null
}

variable "service_account" {
  description = "The service account to be used by the application."
  type        = string
  default     = null
}

variable "create_sa_user_role" {
  description = "If true and a 'service_account' is provided, grants the App Engine service agent 'roles/iam.serviceAccountUser' on the specified service account. This allows the App Engine service to act as the specified service account."
  type        = bool
  default     = true
}

variable "env_variables" {
  description = "A map of environment variables to set for the application."
  type        = map(string)
  default     = {}
}

variable "automatic_scaling" {
  description = <<-EOD
  Configuration for automatic scaling. Leave null to disable.
  Structure differs for Standard and Flexible environments.
  For Standard, the structure is:
  {
    max_concurrent_requests = number
    min_idle_instances      = number
    max_idle_instances      = number
    min_pending_latency     = string # e.g. "0.5s"
    max_pending_latency     = string # e.g. "10s"
    standard_scheduler_settings = {
      min_instances = number
      max_instances = number
    }
  }
  For Flexible, the structure is:
  {
    min_total_instances = number
    max_total_instances = number
    cool_down_period    = string # e.g. "120s"
    cpu_utilization = {
      target_utilization = number # e.g. 0.75
    }
  }
EOD
  type        = any
  default     = null
}

variable "basic_scaling" {
  description = "Configuration for basic scaling (Standard environment only). Leave null to disable."
  type = object({
    max_instances = number
    idle_timeout  = optional(string)
  })
  default = null
}

variable "manual_scaling" {
  description = "Configuration for manual scaling (Standard environment only). Leave null to disable."
  type = object({
    instances = number
  })
  default = null
}

variable "network" {
  description = "Network settings for a Flexible environment. Leave null to use default."
  type = object({
    name = string
  })
  default = null
}

variable "health_check" {
  description = "Health check configuration for a Flexible environment. Contains 'liveness_check' and 'readiness_check'."
  type = object({
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
  })
  default = null
}

variable "noop_on_destroy" {
  description = "If set to true, the application version will not be deleted when the resource is destroyed and traffic will not be migrated to it automatically. This is useful for canary deployments."
  type        = bool
  default     = false
}

variable "traffic_split" {
  description = "A map of version IDs to traffic allocation percentages. The keys are version IDs and values are fractional allocations. The sum of values must be 1.0. If set, creates a traffic split configuration."
  type        = map(number)
  default     = null
}

variable "migrate_traffic" {
  description = "Whether to migrate traffic gradually. If false, traffic is switched instantly. Only applicable if 'traffic_split' is set."
  type        = bool
  default     = false
}

variable "inbound_services" {
  description = "A list of inbound services for the application. Can be 'INBOUND_SERVICE_MAIL', 'INBOUND_SERVICE_MAIL_BOUNCE', 'INBOUND_SERVICE_XMPP_ERROR', 'INBOUND_SERVICE_XMPP_MESSAGE', 'INBOUND_SERVICE_XMPP_SUBSCRIBE', 'INBOUND_SERVICE_XMPP_PRESENCE', 'INBOUND_SERVICE_CHANNEL_PRESENCE', 'INBOUND_SERVICE_WARMUP'."
  type        = list(string)
  default     = []
}

variable "delete_service_on_destroy" {
  description = "If set to true, the service will be deleted when all versions are removed."
  type        = bool
  default     = false
}

variable "database_type" {
  description = "The type of database to use with App Engine. Can be 'CLOUD_FIRESTORE' or 'CLOUD_DATASTORE_COMPATIBILITY'."
  type        = string
  default     = "CLOUD_FIRESTORE"
}
