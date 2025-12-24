variable "project_id" {
  # description: The ID of the Google Cloud project where the App Engine application will be created and deployed.
  description = "The ID of the Google Cloud project where the App Engine application will be created and deployed."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable. If null, no resources will be created.
  default     = null
}

variable "location_id" {
  # description: The location to serve the App Engine application from. See https://cloud.google.com/appengine/docs/locations.
  description = "The location to serve the App Engine application from. See https://cloud.google.com/appengine/docs/locations."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable. If null, no resources will be created.
  default     = null
}

variable "create_app" {
  # description: A boolean flag to control the creation of the `google_app_engine_application` resource. Set to `false` if an App Engine application already exists in the project.
  description = "A boolean flag to control the creation of the `google_app_engine_application` resource. Set to `false` if an App Engine application already exists in the project."
  # type: The data type of the variable.
  type        = bool
  # default: The default value for the variable.
  default     = true
}

variable "database_type" {
  # description: The type of database to use with App Engine.
  description = "The type of database to use with App Engine. Can be 'CLOUD_FIRESTORE' or 'CLOUD_DATASTORE_COMPATIBILITY'."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = null
}

variable "auth_domain" {
  # description: The domain to authenticate users with when using Google Accounts API.
  description = "The domain to authenticate users with when using Google Accounts API."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = null
}

variable "service_name" {
  # description: The name of the App Engine service to deploy. The 'default' service is created if not specified.
  description = "The name of the App Engine service to deploy. The 'default' service is created if not specified."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = "default"
}

variable "version_id" {
  # description: A unique identifier for the version of the service.
  description = "A unique identifier for the version of the service."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = "v1"
}

variable "runtime" {
  # description: The runtime environment for the application, e.g., 'python311', 'go119', 'nodejs18'.
  description = "The runtime environment for the application, e.g., 'python311', 'go119', 'nodejs18'."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = "python311"
}

variable "entrypoint_shell" {
  # description: The shell command to execute to start the application.
  description = "The shell command to execute to start the application."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = "gunicorn -b :$PORT main:app"
}

variable "deployment_zip_source_url" {
  # description: The Google Cloud Storage URL of the zip file containing the application source code.
  description = "The Google Cloud Storage URL of the zip file containing the application source code."
  # type: The data type of thevariable.
  type        = string
  # default: The default value for the variable. If null, no resources will be created.
  default     = null
}

variable "env_variables" {
  # description: A map of environment variables to be made available to the application.
  description = "A map of environment variables to be made available to the application."
  # type: The data type of the variable.
  type        = map(string)
  # default: The default value for the variable.
  default     = {}
}

variable "inbound_services" {
  # description: A list of inbound services that can send traffic to this version. If empty or null, all traffic is allowed.
  description = "A list of inbound services that can send traffic to this version. If empty or null, all traffic is allowed. See https://cloud.google.com/appengine/docs/standard/go/config/appref for valid values."
  # type: The data type of the variable.
  type        = list(string)
  # default: The default value for the variable.
  default     = null
}

variable "instance_class" {
  # description: The instance class to use for this version.
  description = "The instance class to use for this version. See https://cloud.google.com/appengine/docs/standard#instance_classes for valid values."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = "F1"
}

variable "scaling_type" {
  # description: The type of scaling to use for this version. Must be one of 'automatic', 'basic', or 'manual'.
  description = "The type of scaling to use for this version. Must be one of 'automatic', 'basic', or 'manual'."
  # type: The data type of the variable.
  type        = string
  # default: The default value for the variable.
  default     = "automatic"

  validation {
    # condition: The validation rule for the variable.
    condition     = contains(["automatic", "basic", "manual"], var.scaling_type)
    # error_message: The error message to display if the validation fails.
    error_message = "The scaling_type must be one of 'automatic', 'basic', or 'manual'."
  }
}

variable "automatic_scaling" {
  # description: Configuration for automatic scaling. Used when `scaling_type` is 'automatic'.
  description = "Configuration for automatic scaling. Used when `scaling_type` is 'automatic'. See `google_app_engine_standard_app_version` resource for available fields."
  # type: The data type of the variable.
  type        = any
  # default: The default value for the variable.
  default     = {
    min_idle_instances  = 1
    max_idle_instances  = 3
    max_instances       = 10
    max_pending_latency = "30ms"
  }
}

variable "basic_scaling" {
  # description: Configuration for basic scaling. Used when `scaling_type` is 'basic'.
  description = "Configuration for basic scaling. Used when `scaling_type` is 'basic'. See `google_app_engine_standard_app_version` resource for available fields."
  # type: The data type of the variable.
  type        = any
  # default: The default value for the variable.
  default     = null
}

variable "manual_scaling" {
  # description: Configuration for manual scaling. Used when `scaling_type` is 'manual'.
  description = "Configuration for manual scaling. Used when `scaling_type` is 'manual'. See `google_app_engine_standard_app_version` resource for available fields."
  # type: The data type of the variable.
  type        = any
  # default: The default value for the variable.
  default     = null
}

variable "delete_service_on_destroy" {
  # description: If set to true, the service will be deleted when the last version is deleted.
  description = "If set to true, the service will be deleted when the last version is deleted."
  # type: The data type of the variable.
  type        = bool
  # default: The default value for the variable.
  default     = false
}

variable "noop_on_destroy" {
  # description: If set to true, Terraform will not delete the version on destroy, but will remove it from the state.
  description = "If set to true, Terraform will not delete the version on destroy, but will remove it from the state."
  # type: The data type of the variable.
  type        = bool
  # default: The default value for the variable.
  default     = false
}

variable "traffic_split" {
  # description: A map defining the traffic split for the service. If set, a `google_app_engine_service_split_traffic` resource will be created. Example: `{ allocations = { "v1" = 0.9, "v2-canary" = 0.1 }, shard_by = "IP" }`.
  description = "A map defining the traffic split for the service. If set, a `google_app_engine_service_split_traffic` resource will be created. Example: `{ allocations = { \"v1\" = 0.9, \"v2-canary\" = 0.1 }, shard_by = \"IP\" }`."
  # type: The data type of the variable.
  type        = any
  # default: The default value for the variable.
  default     = null
}
