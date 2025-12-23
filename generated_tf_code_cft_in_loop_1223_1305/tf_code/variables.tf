variable "create_app" {
  description = "If true, creates the App Engine application. This is a one-time operation per project."
  type        = bool
  default     = true
}

variable "delete_service_on_destroy" {
  description = "If set to true, the service will be deleted when the app version is destroyed. (Standard environment only)"
  type        = bool
  default     = false
}

variable "deployment" {
  description = "Deployment configuration for the app version. For a standard environment, this should be a map with a 'zip' block containing 'source_url'. For a flexible environment, it can contain either a 'zip' block or a 'container' block with 'image'. Example for standard: { zip = { source_url = \"gs://my-bucket/my-app.zip\" } }. Example for flex: { container = { image = \"gcr.io/google-appengine/python-hello-world\" } }. Note: When using a 'zip' deployment with 'source_url', the deploying principal must have 'Storage Object Viewer' (roles/storage.objectViewer) permissions on the GCS bucket."
  type = object({
    zip = optional(object({
      files_count = optional(number)
      source_url  = string
    }))
    container = optional(object({
      image = string
    }))
  })
  default = null
  validation {
    condition     = var.deployment != null ? (try(var.deployment.zip, null) != null || try(var.deployment.container, null) != null) : true
    error_message = "If 'deployment' is specified, at least one of 'zip' or 'container' must be specified within it."
  }
}

variable "entrypoint" {
  description = "The entrypoint for the application, which is required for all deployments. This should be a map containing a 'shell' key with the command string. Example: { shell = \"gunicorn -b :$PORT main:app\" }"
  type = object({
    shell = string
  })
  default = null
}

variable "env_type" {
  description = "The App Engine environment type. Must be one of 'standard' or 'flex'."
  type        = string
  default     = null
  validation {
    condition     = var.env_type == null ? true : contains(["standard", "flex"], var.env_type)
    error_message = "The env_type must be either 'standard' or 'flex'."
  }
}

variable "env_variables" {
  description = "A map of environment variables to forward to the application."
  type        = map(string)
  default     = {}
}

variable "flex_settings" {
  description = "A map of settings specific to the flexible environment. The 'liveness_check' and 'readiness_check' blocks are required by App Engine Flex. If not specified, default check paths will be used. Can also contain optional keys for 'resources', 'network', 'automatic_scaling', and 'vpc_access_connector'."
  type = object({
    liveness_check = optional(object({
      check_interval    = optional(string)
      failure_threshold = optional(number)
      host              = optional(string)
      initial_delay     = optional(string)
      path              = optional(string)
      success_threshold = optional(number)
      timeout           = optional(string)
    }))
    readiness_check = optional(object({
      app_start_timeout = optional(string)
      check_interval    = optional(string)
      failure_threshold = optional(number)
      host              = optional(string)
      path              = optional(string)
      success_threshold = optional(number)
      timeout           = optional(string)
    }))
    automatic_scaling = optional(object({
      cool_down_period    = optional(string)
      max_total_instances = optional(number)
      min_total_instances = optional(number)
      cpu_utilization = optional(object({
        aggregation_window_length = optional(string)
        target_utilization        = number
      }))
    }))
    network = optional(object({
      forwarded_ports  = optional(list(string))
      instance_tag     = optional(string)
      name             = string
      session_affinity = optional(bool)
      subnetwork       = optional(string)
    }))
    resources = optional(object({
      cpu       = optional(number)
      disk_gb   = optional(number)
      memory_gb = optional(number)
      volumes = optional(list(object({
        name        = string
        size_gb     = number
        volume_type = string
      })))
    }))
    vpc_access_connector = optional(object({
      name = string
    }))
  })
  default = {}
}

variable "inbound_services" {
  description = "A list of inbound services for the App Engine version. Allowed values are 'INBOUND_SERVICE_MAIL', 'INBOUND_SERVICE_MAIL_BOUNCE', 'INBOUND_SERVICE_XMPP_ERROR', 'INBOUND_SERVICE_XMPP_MESSAGE', 'INBOUND_SERVICE_XMPP_SUBSCRIBE', 'INBOUND_SERVICE_XMPP_PRESENCE', 'INBOUND_SERVICE_CHANNEL_PRESENCE', and 'INBOUND_SERVICE_WARMUP'."
  type        = list(string)
  default     = null
}

variable "instance_class" {
  description = "Instance class that is used to run this version. Valid values are F1, F2, F4, F4_1G, B1, B2, B4, B8, B4_1G. (Standard environment only)"
  type        = string
  default     = null
}

variable "location_id" {
  description = "The location to serve the App Engine application from. Required if create_app is true."
  type        = string
  default     = null
}

variable "noop_on_destroy" {
  description = "If set to true, the app version will not be deleted when the resource is destroyed. This is useful for managing traffic splits."
  type        = bool
  default     = false
}

variable "project_id" {
  description = "The ID of the Google Cloud project that the App Engine application belongs to."
  type        = string
  default     = null
}

variable "runtime" {
  description = "The runtime environment for the application. For example, 'python311' or 'nodejs20'."
  type        = string
  default     = null
}

variable "service_account" {
  description = "The service account to be used for the application. If not provided, the App Engine default service account is used. It is recommended to use a dedicated service account with least privileges."
  type        = string
  default     = null
}

variable "service_name" {
  description = "The name of the service to deploy."
  type        = string
  default     = null
}

variable "standard_scaling" {
  description = "Scaling settings for the standard environment. This should be a map containing exactly one of the following keys: 'automatic_scaling', 'basic_scaling', or 'manual_scaling'. The value should be an object with the settings for that scaling type."
  type = object({
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
      }))
    }))
    basic_scaling = optional(object({
      idle_timeout  = string
      max_instances = number
    }))
    manual_scaling = optional(object({
      instances = number
    }))
  })
  default = {}
  validation {
    condition = (
      (try(var.standard_scaling.automatic_scaling, null) != null ? 1 : 0) +
      (try(var.standard_scaling.basic_scaling, null) != null ? 1 : 0) +
      (try(var.standard_scaling.manual_scaling, null) != null ? 1 : 0)
    ) <= 1
    error_message = "Only one of automatic_scaling, basic_scaling, or manual_scaling can be specified."
  }
}

variable "version_id" {
  description = "The version ID for the new deployment."
  type        = string
  default     = null
}
