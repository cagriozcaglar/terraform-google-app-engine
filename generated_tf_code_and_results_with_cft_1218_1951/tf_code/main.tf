# This resource manages the top-level App Engine application for a project.
# There can be only one App Engine application per GCP project.
resource "google_app_engine_application" "app" {
  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The location to serve the app from.
  location_id = var.location_id
  # The type of database to use.
  # Can be CLOUD_FIRESTORE or CLOUD_DATASTORE_COMPATIBILITY.
  database_type = var.database_type
  # The domain to authenticate users with when using App Engine's User API.
  auth_domain = var.auth_domain

  # The feature settings to apply to the application.
  feature_settings {
    # If true, health checks are split between the instance and the load balancer.
    split_health_checks = var.feature_settings.split_health_checks
  }

  # Dynamic block for Identity-Aware Proxy configuration.
  # This block is only included if the 'iap' variable is not null.
  dynamic "iap" {
    for_each = var.iap != null ? [var.iap] : []
    content {
      # The OAuth2 client ID used for IAP.
      oauth2_client_id = iap.value.oauth2_client_id
      # The OAuth2 client secret used for IAP.
      # This is a sensitive value.
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }
}

# This resource manages a version for a flexible environment App Engine service.
# It iterates over the 'flexible_services' map to create multiple services/versions.
resource "google_app_engine_flexible_app_version" "flexible" {
  for_each = var.flexible_services

  # The ID of the project in which the resource belongs.
  project = google_app_engine_application.app.project
  # The name of the service to which this version belongs.
  service = each.key
  # The identifier for this version.
  version_id = each.value.version_id
  # The runtime environment for the application. 'custom' for containers.
  runtime = each.value.runtime
  # The desired serving status for the version.
  serving_status = each.value.serving_status
  # The deployment configuration for the version.
  deployment {
    container {
      # The full URL to the container image in Artifact Registry or GCR.
      image = each.value.deployment_image_url
    }
  }
  # A map of environment variables available to the application.
  env_variables = each.value.env_variables
  # If true, prevents Terraform from deleting the version on 'destroy'.
  noop_on_destroy = each.value.noop_on_destroy

  # A list of inbound services that can be called by the application.
  inbound_services = each.value.inbound_services
  # The API version of the App Engine runtime environment.
  runtime_api_version = each.value.runtime_api_version

  # Dynamic block for liveness check configuration.
  dynamic "liveness_check" {
    for_each = each.value.liveness_check != null ? [each.value.liveness_check] : []
    content {
      path              = liveness_check.value.path
      host              = lookup(liveness_check.value, "host", null)
      timeout           = lookup(liveness_check.value, "timeout", null)
      check_interval    = lookup(liveness_check.value, "check_interval", null)
      failure_threshold = lookup(liveness_check.value, "failure_threshold", null)
      success_threshold = lookup(liveness_check.value, "success_threshold", null)
      initial_delay     = lookup(liveness_check.value, "initial_delay", null)
    }
  }

  # Dynamic block for readiness check configuration.
  dynamic "readiness_check" {
    for_each = each.value.readiness_check != null ? [each.value.readiness_check] : []
    content {
      path              = readiness_check.value.path
      host              = lookup(readiness_check.value, "host", null)
      timeout           = lookup(readiness_check.value, "timeout", null)
      check_interval    = lookup(readiness_check.value, "check_interval", null)
      failure_threshold = lookup(readiness_check.value, "failure_threshold", null)
      success_threshold = lookup(readiness_check.value, "success_threshold", null)
      app_start_timeout = lookup(readiness_check.value, "app_start_timeout", null)
    }
  }

  # Dynamic block for machine resource configuration.
  dynamic "resources" {
    for_each = each.value.resources != null ? [each.value.resources] : []
    content {
      cpu       = lookup(resources.value, "cpu", null)
      memory_gb = lookup(resources.value, "memory_gb", null)
      disk_gb   = lookup(resources.value, "disk_gb", null)
      dynamic "volumes" {
        for_each = lookup(resources.value, "volumes", [])
        content {
          name        = volumes.value.name
          volume_type = volumes.value.volume_type
          size_gb     = volumes.value.size_gb
        }
      }
    }
  }

  # Dynamic block for network configuration.
  dynamic "network" {
    for_each = each.value.network != null ? [each.value.network] : []
    content {
      name             = network.value.name
      forwarded_ports  = lookup(network.value, "forwarded_ports", null)
      instance_tag     = lookup(network.value, "instance_tag", null)
      subnetwork       = lookup(network.value, "subnetwork", null)
      session_affinity = lookup(network.value, "session_affinity", null)
    }
  }

  # Dynamic block for automatic scaling settings.
  dynamic "automatic_scaling" {
    for_each = each.value.automatic_scaling != null ? [each.value.automatic_scaling] : []
    content {
      cool_down_period    = lookup(automatic_scaling.value, "cool_down_period", null)
      min_total_instances = lookup(automatic_scaling.value, "min_total_instances", null)
      max_total_instances = lookup(automatic_scaling.value, "max_total_instances", null)
      cpu_utilization {
        target_utilization = automatic_scaling.value.cpu_utilization.target_utilization
      }
    }
  }
}

# This resource manages a version for a standard environment App Engine service.
# It iterates over the 'standard_services' map to create multiple services/versions.
resource "google_app_engine_standard_app_version" "standard" {
  for_each = var.standard_services

  # The ID of the project in which the resource belongs.
  # This implicitly depends on the 'google_app_engine_application' resource.
  project = google_app_engine_application.app.project
  # The name of the service to which this version belongs.
  service = each.key
  # The identifier for this version.
  version_id = each.value.version_id
  # The runtime environment for the application.
  runtime = each.value.runtime
  # The entrypoint for the application.
  entrypoint {
    shell = each.value.entrypoint_shell
  }
  # The deployment configuration for the version.
  deployment {
    zip {
      # The URL of the zipped source code in a GCS bucket.
      source_url = each.value.deployment_source_url
    }
  }
  # A map of environment variables available to the application.
  env_variables = each.value.env_variables
  # If true, prevents Terraform from deleting the version on 'destroy'.
  noop_on_destroy = each.value.noop_on_destroy

  # The instance class to use for the version.
  instance_class = each.value.instance_class
  # A list of inbound services that can be called by the application.
  inbound_services = each.value.inbound_services
  # Whether App Engine APIs are available.
  app_engine_apis = each.value.app_engine_apis
  # Whether the application can handle concurrent requests.
  threadsafe = each.value.threadsafe

  # Dynamic block for automatic scaling settings.
  # Included only if automatic_scaling is defined for the service.
  dynamic "automatic_scaling" {
    for_each = try(each.value.scaling.automatic_scaling, null) != null ? [each.value.scaling.automatic_scaling] : []
    content {
      max_concurrent_requests   = lookup(automatic_scaling.value, "max_concurrent_requests", null)
      min_idle_instances        = lookup(automatic_scaling.value, "min_idle_instances", null)
      max_idle_instances        = lookup(automatic_scaling.value, "max_idle_instances", null)
      min_pending_latency       = lookup(automatic_scaling.value, "min_pending_latency", null)
      max_pending_latency       = lookup(automatic_scaling.value, "max_pending_latency", null)
      standard_scheduler_settings {
        target_cpu_utilization        = lookup(automatic_scaling.value.standard_scheduler_settings, "target_cpu_utilization", null)
        target_throughput_utilization = lookup(automatic_scaling.value.standard_scheduler_settings, "target_throughput_utilization", null)
        min_instances                 = lookup(automatic_scaling.value.standard_scheduler_settings, "min_instances", null)
        max_instances                 = lookup(automatic_scaling.value.standard_scheduler_settings, "max_instances", null)
      }
    }
  }

  # Dynamic block for basic scaling settings.
  # Included only if basic_scaling is defined for the service.
  dynamic "basic_scaling" {
    for_each = try(each.value.scaling.basic_scaling, null) != null ? [each.value.scaling.basic_scaling] : []
    content {
      max_instances = basic_scaling.value.max_instances
      idle_timeout  = lookup(basic_scaling.value, "idle_timeout", null)
    }
  }

  # Dynamic block for manual scaling settings.
  # Included only if manual_scaling is defined for the service.
  dynamic "manual_scaling" {
    for_each = try(each.value.scaling.manual_scaling, null) != null ? [each.value.scaling.manual_scaling] : []
    content {
      instances = manual_scaling.value.instances
    }
  }
}

# This resource manages traffic splitting for an App Engine service.
# It iterates over the 'traffic_splits' map to configure traffic for multiple services.
resource "google_app_engine_service_split_traffic" "split" {
  for_each = var.traffic_splits

  # The ID of the project in which the resource belongs.
  project = google_app_engine_application.app.project
  # The name of the service to configure traffic for.
  service = each.key
  # If false, the traffic split is not migrated to the new version.
  migrate_traffic = false
  # The traffic split configuration.
  split {
    # The method to split traffic by. Can be 'IP', 'COOKIE', or 'RANDOM'.
    shard_by = each.value.shard_by
    # A map of version IDs to traffic allocation percentage (0.0 to 1.0).
    allocations = each.value.allocations
  }

  # Ensures that the versions being targeted by the traffic split are created first.
  depends_on = [
    google_app_engine_standard_app_version.standard,
    google_app_engine_flexible_app_version.flexible
  ]
}
