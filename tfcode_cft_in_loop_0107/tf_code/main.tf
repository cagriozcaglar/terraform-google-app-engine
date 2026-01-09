# These local variables are used to conditionally create resources.
# This allows the module to create just the application, or the application and a version.
locals {
  # app_enabled is true if the App Engine application itself should be created.
  app_enabled = var.project_id != null && var.location_id != null
  # version_enabled is true if a new version should be deployed.
  version_enabled = local.app_enabled && var.version_id != null && var.env_type != null
  # version is a helper to reference the created version resource, regardless of its type (standard or flexible).
  version = local.version_enabled ? one(concat(
    google_app_engine_standard_app_version.standard,
    google_app_engine_flexible_app_version.flexible
  )) : null
}

# Retrieves project data, including the project number needed for the App Engine service agent.
data "google_project" "project" {
  # Only retrieve data if the module will create resources.
  count = local.app_enabled ? 1 : 0

  # The ID of the project.
  project_id = var.project_id
}

# Grants the App Engine service agent the Service Account User role on the custom service account.
# This is necessary for the App Engine service agent to be able to impersonate the custom service account.
resource "google_service_account_iam_member" "app_engine_sa_user" {
  # Create this resource only if a version with a custom service account is being deployed and role creation is enabled.
  count = local.version_enabled && var.service_account != null && var.create_sa_user_role ? 1 : 0

  # The fully-qualified name of the service account to apply the policy to. Can be the email address.
  service_account_id = var.service_account
  # The role to grant.
  role = "roles/iam.serviceAccountUser"
  # The member to grant the role to, which is the App Engine service agent for the project.
  member = "serviceAccount:service-${data.google_project.project[0].number}@gcp-sa-appengine.iam.gserviceaccount.com"
}

# The App Engine application resource, which is a top-level resource for a project.
# It defines the location and database type for the App Engine services.
resource "google_app_engine_application" "app" {
  # Only create resource if required variables are provided.
  count = local.app_enabled ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The location to deploy the App Engine application.
  location_id = var.location_id
  # The type of database to use with App Engine.
  database_type = var.database_type
}

# Deploys a new version to the App Engine Flexible Environment.
# This resource is only created if env_type is 'flexible'.
resource "google_app_engine_flexible_app_version" "flexible" {
  # Create this resource only if the environment type is 'flexible' and a version is being deployed.
  count = local.version_enabled && var.env_type == "flexible" ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The name of the service to which this version belongs.
  service = var.service_name
  # A unique identifier for the version.
  version_id = var.version_id
  # A container-based deployment for the flexible environment must have a 'custom' runtime.
  runtime = "custom"
  # The service account to be used by the application.
  service_account = var.service_account
  # A map of environment variables to set for the application.
  env_variables = var.env_variables
  # If set to true, the service will be deleted when all versions are removed.
  delete_service_on_destroy = var.delete_service_on_destroy
  # If true, do not delete the version on destroy.
  noop_on_destroy = var.noop_on_destroy

  # The deployment configuration for the application source code.
  deployment {
    # The container image configuration.
    container {
      # The full URL of the container image.
      image = var.deployment_source.container.image
    }
  }

  # Liveness check configuration.
  dynamic "liveness_check" {
    # Iterate only if health_check and liveness_check are defined.
    for_each = var.health_check != null && var.health_check.liveness_check != null ? [var.health_check.liveness_check] : []
    content {
      # The path to the health check endpoint.
      path = liveness_check.value.path
      # Time interval between health checks.
      check_interval = liveness_check.value.check_interval
      # Time limit for a health check response.
      timeout = liveness_check.value.timeout
      # Number of consecutive failed checks required before considering an instance unhealthy.
      failure_threshold = liveness_check.value.failure_threshold
      # Number of consecutive successful checks required before considering an instance healthy.
      success_threshold = liveness_check.value.success_threshold
      # The host header to use when performing a health check.
      host = liveness_check.value.host
      # The initial delay before starting to execute health checks.
      initial_delay = liveness_check.value.initial_delay
    }
  }

  # Readiness check configuration.
  dynamic "readiness_check" {
    # Iterate only if health_check and readiness_check are defined.
    for_each = var.health_check != null && var.health_check.readiness_check != null ? [var.health_check.readiness_check] : []
    content {
      # The path to the readiness check endpoint.
      path = readiness_check.value.path
      # Time interval between health checks.
      check_interval = readiness_check.value.check_interval
      # Time limit for a health check response.
      timeout = readiness_check.value.timeout
      # Number of consecutive failed checks required before considering an instance unhealthy.
      failure_threshold = readiness_check.value.failure_threshold
      # Number of consecutive successful checks required before considering an instance healthy.
      success_threshold = readiness_check.value.success_threshold
      # The host header to use when performing a health check.
      host = readiness_check.value.host
      # A duration to wait for the application to start before the first readiness check is performed.
      app_start_timeout = readiness_check.value.app_start_timeout
    }
  }

  # Configuration for automatic scaling.
  dynamic "automatic_scaling" {
    # Iterate only if automatic_scaling is defined.
    for_each = var.automatic_scaling != null ? [var.automatic_scaling] : []
    content {
      # Minimum number of instances to maintain.
      min_total_instances = lookup(automatic_scaling.value, "min_total_instances", null)
      # Maximum number of instances to scale up to.
      max_total_instances = lookup(automatic_scaling.value, "max_total_instances", null)
      # The cool-down period after a scaling event.
      cool_down_period = lookup(automatic_scaling.value, "cool_down_period", null)

      # CPU utilization based scaling.
      dynamic "cpu_utilization" {
        # Iterate only if cpu_utilization is defined within automatic_scaling.
        for_each = try(automatic_scaling.value.cpu_utilization, null) != null ? [automatic_scaling.value.cpu_utilization] : []
        content {
          # The target CPU utilization fraction to maintain.
          target_utilization = cpu_utilization.value.target_utilization
        }
      }
    }
  }

  # Network settings.
  dynamic "network" {
    # Iterate only if network is defined.
    for_each = var.network != null ? [var.network] : []
    content {
      # The name of the VPC network to deploy the service into.
      name = network.value.name
    }
  }

  # Ensure the App Engine application itself is created before deploying a version.
  # Also, ensure the IAM role is bound if a service account is used.
  depends_on = [
    google_app_engine_application.app,
    google_service_account_iam_member.app_engine_sa_user,
  ]

  lifecycle {
    # Checks that a container image is provided for flexible environment deployment.
    precondition {
      condition     = var.deployment_source.container != null
      error_message = "The 'deployment_source.container' block must be specified for a flexible environment."
    }
    # Checks that automatic_scaling does not contain settings for the standard environment.
    precondition {
      condition = var.automatic_scaling == null || (
        lookup(var.automatic_scaling, "max_concurrent_requests", null) == null &&
        lookup(var.automatic_scaling, "min_idle_instances", null) == null &&
        lookup(var.automatic_scaling, "max_idle_instances", null) == null &&
        lookup(var.automatic_scaling, "min_pending_latency", null) == null &&
        lookup(var.automatic_scaling, "max_pending_latency", null) == null &&
      lookup(var.automatic_scaling, "standard_scheduler_settings", null) == null)
      error_message = "Standard environment scaling options cannot be used with a flexible environment."
    }
  }
}

# Deploys a new version to the App Engine Standard Environment.
# This resource is only created if env_type is 'standard'.
resource "google_app_engine_standard_app_version" "standard" {
  # Create this resource only if the environment type is 'standard' and a version is being deployed.
  count = local.version_enabled && var.env_type == "standard" ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The name of the service to which this version belongs.
  service = var.service_name
  # A unique identifier for the version.
  version_id = var.version_id
  # The runtime environment for the application.
  runtime = var.runtime
  # A map of environment variables to set for the application.
  env_variables = var.env_variables
  # The instance class to use.
  instance_class = var.instance_class
  # The service account to be used by the application.
  service_account = var.service_account
  # A list of inbound services for the application.
  inbound_services = var.inbound_services
  # If set to true, the service will be deleted when all versions are removed.
  delete_service_on_destroy = var.delete_service_on_destroy
  # If true, do not delete the version on destroy.
  noop_on_destroy = var.noop_on_destroy

  # The entrypoint for the application.
  dynamic "entrypoint" {
    # Iterate only if entrypoint is defined.
    for_each = var.entrypoint != null ? [var.entrypoint] : []
    content {
      # The command to run on startup.
      shell = entrypoint.value.shell
    }
  }

  # The deployment configuration for the application source code.
  dynamic "deployment" {
    # Iterate only if deployment source is a zip file.
    for_each = var.deployment_source.zip != null ? [var.deployment_source.zip] : []
    content {
      # The zip file configuration.
      zip {
        # The URL of the source code zip file in a GCS bucket.
        source_url = deployment.value.source_url
      }
    }
  }

  # Configuration for automatic scaling.
  dynamic "automatic_scaling" {
    # Iterate only if automatic_scaling is defined.
    for_each = var.automatic_scaling != null ? [var.automatic_scaling] : []
    content {
      # Number of concurrent requests an automatic scaling instance can accept before the scheduler spawns a new instance.
      max_concurrent_requests = lookup(automatic_scaling.value, "max_concurrent_requests", null)
      # Minimum number of idle instances that should be maintained for this version.
      min_idle_instances = lookup(automatic_scaling.value, "min_idle_instances", null)
      # Maximum number of idle instances that should be maintained for this version.
      max_idle_instances = lookup(automatic_scaling.value, "max_idle_instances", null)
      # Maximum amount of time that a request should wait in the pending queue before starting a new instance to handle it.
      max_pending_latency = lookup(automatic_scaling.value, "max_pending_latency", null)
      # Minimum amount of time that a request should wait in the pending queue before starting a new instance to handle it.
      min_pending_latency = lookup(automatic_scaling.value, "min_pending_latency", null)

      # Standard scheduler settings.
      dynamic "standard_scheduler_settings" {
        # Iterate only if standard_scheduler_settings is defined within automatic_scaling.
        for_each = try(automatic_scaling.value.standard_scheduler_settings, null) != null ? [automatic_scaling.value.standard_scheduler_settings] : []
        content {
          # The minimum number of instances to run for this version.
          min_instances = lookup(standard_scheduler_settings.value, "min_instances", null)
          # The maximum number of instances to run for this version.
          max_instances = lookup(standard_scheduler_settings.value, "max_instances", null)
        }
      }
    }
  }

  # Configuration for basic scaling.
  dynamic "basic_scaling" {
    # Iterate only if basic_scaling is defined.
    for_each = var.basic_scaling != null ? [var.basic_scaling] : []
    content {
      # The maximum number of instances to create for this version.
      max_instances = basic_scaling.value.max_instances
      # Duration of time after the last request that an instance must wait before shutting down.
      idle_timeout = basic_scaling.value.idle_timeout
    }
  }

  # Configuration for manual scaling.
  dynamic "manual_scaling" {
    # Iterate only if manual_scaling is defined.
    for_each = var.manual_scaling != null ? [var.manual_scaling] : []
    content {
      # The number of instances to allocate to the service.
      instances = manual_scaling.value.instances
    }
  }

  # Ensure the App Engine application itself is created before deploying a version.
  # Also, ensure the IAM role is bound if a service account is used.
  depends_on = [
    google_app_engine_application.app,
    google_service_account_iam_member.app_engine_sa_user,
  ]

  lifecycle {
    # Checks that a runtime is specified for the standard environment.
    precondition {
      condition     = var.runtime != null
      error_message = "The 'runtime' variable must be specified for a standard environment."
    }
    # Checks that an entrypoint is specified for the standard environment.
    precondition {
      condition     = var.entrypoint != null
      error_message = "The 'entrypoint' variable must be specified for a standard environment."
    }
    # Checks that a zip source is provided for the standard environment.
    precondition {
      condition     = var.deployment_source.zip != null
      error_message = "The 'deployment_source.zip' block must be specified for a standard environment."
    }
    # Checks that only one scaling type is configured.
    precondition {
      condition     = length([for s in [var.automatic_scaling, var.basic_scaling, var.manual_scaling] : s if s != null]) <= 1
      error_message = "Only one of 'automatic_scaling', 'basic_scaling', or 'manual_scaling' can be configured at a time for the standard environment."
    }
    # Checks that automatic_scaling does not contain settings for the flexible environment.
    precondition {
      condition = var.automatic_scaling == null || (
        lookup(var.automatic_scaling, "min_total_instances", null) == null &&
        lookup(var.automatic_scaling, "max_total_instances", null) == null &&
        lookup(var.automatic_scaling, "cool_down_period", null) == null &&
      lookup(var.automatic_scaling, "cpu_utilization", null) == null)
      error_message = "Flexible environment scaling options (min_total_instances, max_total_instances, cool_down_period, cpu_utilization) cannot be used with a standard environment."
    }
  }
}

# Manages the traffic split for the service.
# This resource is only created if a traffic_split is defined.
resource "google_app_engine_service_split_traffic" "split" {
  # Create this resource only if traffic_split is configured and a version is being deployed.
  count = local.version_enabled && var.traffic_split != null ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The name of the service to which this version belongs.
  service = var.service_name
  # Whether to migrate traffic gradually.
  migrate_traffic = var.migrate_traffic

  # The traffic split configuration.
  split {
    # A map of version IDs to traffic allocation percentages.
    allocations = var.traffic_split
  }

  # Ensure the new version is deployed before attempting to split traffic to it.
  depends_on = [
    google_app_engine_standard_app_version.standard,
    google_app_engine_flexible_app_version.flexible,
  ]
}
