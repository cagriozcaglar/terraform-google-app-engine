locals {
  # A local variable to determine if the core resources should be created.
  # This prevents creation if essential variables like project_id, location_id,
  # and deployment_zip_source_url are not provided.
  enabled = var.project_id != null && var.location_id != null && var.deployment_zip_source_url != null
}

# Creates the App Engine application in the specified project. This is a one-time operation per project.
# The resource will not be created if `var.create_app` is set to `false` or if required variables are missing.
resource "google_app_engine_application" "app" {
  # count: The number of instances of this resource to create.
  count = var.create_app && local.enabled ? 1 : 0

  # The ID of the project in which to create the App Engine application.
  project = var.project_id
  # The location to serve the app from.
  location_id = var.location_id
  # The type of database to use with App Engine.
  database_type = var.database_type
  # The domain to authenticate users with when using Google Accounts API.
  auth_domain = var.auth_domain
}

# Deploys a new standard version for an App Engine service.
# The resource will not be created if required variables are missing.
resource "google_app_engine_standard_app_version" "main" {
  # count: The number of instances of this resource to create.
  count = local.enabled ? 1 : 0

  # The project ID this version belongs to.
  project = var.project_id
  # The name of the service this version belongs to.
  service = var.service_name
  # A unique identifier for this version.
  version_id = var.version_id
  # The runtime environment for this version.
  runtime = var.runtime
  # Environment variables available to this version.
  env_variables = var.env_variables
  # The instance class to use for this version.
  instance_class = var.instance_class
  # A list of inbound services that can send traffic to this version.
  inbound_services = var.inbound_services
  # If true, the service will be deleted when the last version is destroyed.
  delete_service_on_destroy = var.delete_service_on_destroy
  # If true, Terraform will not delete the version on destroy.
  noop_on_destroy = var.noop_on_destroy

  # The entrypoint for the application.
  entrypoint {
    # The shell command to execute to start the application.
    shell = var.entrypoint_shell
  }

  # The source code deployment configuration.
  deployment {
    # The zip file containing the source code.
    zip {
      # The GCS URL of the source code zip file.
      source_url = var.deployment_zip_source_url
    }
  }

  # This dynamic block configures automatic scaling if `var.scaling_type` is 'automatic'.
  dynamic "automatic_scaling" {
    # for_each: Iterates over a collection to create nested blocks.
    for_each = var.scaling_type == "automatic" && var.automatic_scaling != null ? [var.automatic_scaling] : []
    # content: The nested block content.
    content {
      # The maximum number of concurrent requests an instance can accept.
      max_concurrent_requests = lookup(automatic_scaling.value, "max_concurrent_requests", null)
      # The maximum number of idle instances.
      max_idle_instances = lookup(automatic_scaling.value, "max_idle_instances", null)
      # The maximum amount of time a request should wait in the pending queue.
      max_pending_latency = lookup(automatic_scaling.value, "max_pending_latency", null)
      # The minimum number of idle instances.
      min_idle_instances = lookup(automatic_scaling.value, "min_idle_instances", null)
      # The minimum amount of time a request should wait in the pending queue.
      min_pending_latency = lookup(automatic_scaling.value, "min_pending_latency", null)
      # Scheduler settings for standard App Engine.
      standard_scheduler_settings {
        # The maximum number of instances to run.
        max_instances = lookup(automatic_scaling.value, "max_instances", null)
        # The minimum number of instances to run.
        min_instances = lookup(automatic_scaling.value, "min_instances", null)
        # The target CPU utilization for scaling.
        target_cpu_utilization = lookup(automatic_scaling.value, "target_cpu_utilization", null)
        # The target throughput utilization for scaling.
        target_throughput_utilization = lookup(automatic_scaling.value, "target_throughput_utilization", null)
      }
    }
  }

  # This dynamic block configures basic scaling if `var.scaling_type` is 'basic'.
  dynamic "basic_scaling" {
    # for_each: Iterates over a collection to create nested blocks.
    for_each = var.scaling_type == "basic" && var.basic_scaling != null ? [var.basic_scaling] : []
    # content: The nested block content.
    content {
      # The maximum number of instances to create for this version.
      max_instances = lookup(basic_scaling.value, "max_instances", 1)
      # The instance will be shut down after this amount of time of inactivity.
      idle_timeout = lookup(basic_scaling.value, "idle_timeout", null)
    }
  }

  # This dynamic block configures manual scaling if `var.scaling_type` is 'manual'.
  dynamic "manual_scaling" {
    # for_each: Iterates over a collection to create nested blocks.
    for_each = var.scaling_type == "manual" && var.manual_scaling != null ? [var.manual_scaling] : []
    # content: The nested block content.
    content {
      # The number of instances to assign to the service at the start.
      instances = lookup(manual_scaling.value, "instances", 1)
    }
  }

  # depends_on: Explicitly specifies dependencies for resource creation.
  depends_on = [google_app_engine_application.app]
}

# Manages the traffic split for the App Engine service.
# This resource is created only if the `var.traffic_split` variable is provided and resources are enabled.
resource "google_app_engine_service_split_traffic" "split" {
  # count: The number of instances of this resource to create.
  count = var.traffic_split != null && local.enabled ? 1 : 0

  # The project ID of the service.
  project = var.project_id
  # The name of the service to split traffic for.
  service = var.service_name
  # If true, all traffic is migrated to the latest version.
  migrate_traffic = false

  # The traffic split configuration.
  split {
    # Method used to shard traffic. Can be 'IP' or 'COOKIE'.
    shard_by = lookup(var.traffic_split, "shard_by", "IP")
    # A map of version IDs to traffic allocation percentage (must sum to 1.0).
    allocations = lookup(var.traffic_split, "allocations", {})
  }

  # depends_on: Ensures the version is deployed before traffic is split.
  depends_on = [google_app_engine_standard_app_version.main]
}
