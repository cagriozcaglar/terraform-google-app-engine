# This data source provides the project of the user running Terraform.
data "google_client_config" "current" {}

locals {
  project_id = coalesce(var.project_id, data.google_client_config.current.project)

  # Flatten the nested services and versions map into a single map keyed by "service_name/version_id".
  # This makes it easy to use for_each in the version resources.
  all_versions_flat = merge(flatten([
    for service_name, service_config in var.services : [
      for version_id, version_config in service_config.versions : {
        "${service_name}/${version_id}" = {
          service_name = service_name
          version_id   = version_id
          config       = version_config
        }
      }
    ]
  ])...)

  # Filter the flattened map into standard versions.
  standard_versions = {
    for k, v in local.all_versions_flat : k => v
    if v.config.env == "standard"
  }

  # Filter the flattened map into flexible versions.
  flexible_versions = {
    for k, v in local.all_versions_flat : k => v
    if v.config.env == "flexible"
  }

  # Prepare a map for the traffic split resource, containing only services that define a split.
  traffic_splits = {
    for service_name, service_config in var.services : service_name => service_config.split
    if service_config.split != null
  }
}

# This resource manages the App Engine application, which is a top-level resource in a GCP project.
# There can be only one App Engine application per project.
resource "google_app_engine_application" "app" {
  # Controls whether to create the App Engine application resource.
  count = var.create_app ? 1 : 0

  # The project ID to create the application in.
  project = local.project_id

  # The location to serve the application from.
  location_id = var.location_id

  # The type of database to use with the application.
  database_type = var.database_type

  # The domain to authenticate users with.
  auth_domain = var.auth_domain

  # The serving status of the application.
  serving_status = var.serving_status

  # A block to configure feature settings.
  feature_settings {
    # If true, split health checks are enabled.
    split_health_checks = var.feature_settings.split_health_checks
  }

  # Dynamic block for Identity-Aware Proxy (IAP) configuration.
  dynamic "iap" {
    # Iterate only if IAP configuration is provided.
    for_each = var.iap != null ? [var.iap] : []

    content {
      # The OAuth2 client ID for IAP.
      oauth2_client_id = iap.value.oauth2_client_id

      # The OAuth2 client secret for IAP.
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }
}

# This resource manages a version of an App Engine standard environment service.
resource "google_app_engine_standard_app_version" "main" {
  # Create a standard app version for each item in the local.standard_versions map.
  for_each = local.standard_versions

  # The project ID of the project to deploy to.
  project = local.project_id

  # The name of the service this version belongs to.
  service = each.value.service_name

  # The identifier for this version.
  version_id = each.value.version_id

  # The runtime environment for the application.
  runtime = each.value.config.runtime

  # The instance class to use for this version.
  instance_class = each.value.config.standard.instance_class

  # The service account to run the application as.
  service_account = each.value.config.service_account

  # If true, do not stop or delete the version when this resource is destroyed.
  noop_on_destroy = each.value.config.noop_on_destroy

  # If true, the service will be deleted when the last version is deleted.
  delete_service_on_destroy = each.value.config.delete_service_on_destroy

  # A list of inbound services that can call this version.
  inbound_services = each.value.config.inbound_services

  # Environment variables available to the application.
  env_variables = each.value.config.env_variables

  # Dynamic block for automatic scaling settings.
  dynamic "automatic_scaling" {
    for_each = each.value.config.standard.automatic_scaling != null ? [each.value.config.standard.automatic_scaling] : []
    content {
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      max_idle_instances      = automatic_scaling.value.max_idle_instances
      max_pending_latency     = automatic_scaling.value.max_pending_latency
      min_idle_instances      = automatic_scaling.value.min_idle_instances
      min_pending_latency     = automatic_scaling.value.min_pending_latency
      dynamic "standard_scheduler_settings" {
        for_each = automatic_scaling.value.standard_scheduler_settings != null ? [automatic_scaling.value.standard_scheduler_settings] : []
        content {
          max_instances                 = standard_scheduler_settings.value.max_instances
          min_instances                 = standard_scheduler_settings.value.min_instances
          target_cpu_utilization        = standard_scheduler_settings.value.target_cpu_utilization
          target_throughput_utilization = standard_scheduler_settings.value.target_throughput_utilization
        }
      }
    }
  }

  # Dynamic block for basic scaling settings.
  dynamic "basic_scaling" {
    for_each = each.value.config.standard.basic_scaling != null ? [each.value.config.standard.basic_scaling] : []
    content {
      idle_timeout  = basic_scaling.value.idle_timeout
      max_instances = basic_scaling.value.max_instances
    }
  }

  # Dynamic block for manual scaling settings.
  dynamic "manual_scaling" {
    for_each = each.value.config.standard.manual_scaling != null ? [each.value.config.standard.manual_scaling] : []
    content {
      instances = manual_scaling.value.instances
    }
  }

  # Dynamic block for the entrypoint configuration.
  dynamic "entrypoint" {
    # Create this block if an entrypoint shell command is provided.
    for_each = each.value.config.standard.entrypoint_shell != null ? [each.value.config.standard.entrypoint_shell] : []

    content {
      # The shell command to execute to run the application.
      shell = entrypoint.value
    }
  }

  # Deployment configuration.
  deployment {
    # Dynamic block for deploying from a zip file in GCS.
    dynamic "zip" {
      # Create this block if a zip source_url is provided.
      for_each = each.value.config.deployment.zip != null ? [each.value.config.deployment.zip] : []

      content {
        # The GCS URL of the zip file.
        source_url = zip.value.source_url
      }
    }
  }

  # Ensure the App Engine application itself exists before creating a version.
  depends_on = [google_app_engine_application.app]
}

# This resource manages a version of an App Engine flexible environment service.
resource "google_app_engine_flexible_app_version" "main" {
  # Create a flexible app version for each item in the local.flexible_versions map.
  for_each = local.flexible_versions

  # The project ID of the project to deploy to.
  project = local.project_id

  # The name of the service this version belongs to.
  service = each.value.service_name

  # The identifier for this version.
  version_id = each.value.version_id

  # The runtime environment for the application. For flex, this is often "custom".
  runtime = each.value.config.runtime

  # The service account to run the application as.
  service_account = each.value.config.service_account

  # If true, do not stop or delete the version when this resource is destroyed.
  noop_on_destroy = each.value.config.noop_on_destroy

  # If true, the service will be deleted when the last version is deleted.
  delete_service_on_destroy = each.value.config.delete_service_on_destroy

  # Environment variables available to the application.
  env_variables = each.value.config.env_variables

  # Deployment configuration.
  deployment {
    # Dynamic block for deploying a container image.
    dynamic "container" {
      # Create this block if a container image is provided.
      for_each = each.value.config.deployment.container != null ? [each.value.config.deployment.container] : []

      content {
        # The full name of the container image to deploy.
        image = container.value.image
      }
    }
  }

  # Dynamic block for the liveness check configuration.
  dynamic "liveness_check" {
    # Create this block if liveness_check configuration is provided.
    for_each = each.value.config.flexible.liveness_check != null ? [each.value.config.flexible.liveness_check] : []

    content {
      path              = liveness_check.value.path
      check_interval    = liveness_check.value.check_interval
      timeout           = liveness_check.value.timeout
      failure_threshold = liveness_check.value.failure_threshold
      success_threshold = liveness_check.value.success_threshold
      host              = liveness_check.value.host
      initial_delay     = liveness_check.value.initial_delay
    }
  }

  # Dynamic block for the readiness check configuration.
  dynamic "readiness_check" {
    # Create this block if readiness_check configuration is provided.
    for_each = each.value.config.flexible.readiness_check != null ? [each.value.config.flexible.readiness_check] : []

    content {
      path              = readiness_check.value.path
      check_interval    = readiness_check.value.check_interval
      timeout           = readiness_check.value.timeout
      failure_threshold = readiness_check.value.failure_threshold
      success_threshold = readiness_check.value.success_threshold
      host              = readiness_check.value.host
      app_start_timeout = readiness_check.value.app_start_timeout
    }
  }

  # Dynamic block for machine resources configuration.
  dynamic "resources" {
    # Create this block if resources configuration is provided.
    for_each = each.value.config.flexible.resources != null ? [each.value.config.flexible.resources] : []

    content {
      # Number of CPU cores to allocate.
      cpu = resources.value.cpu

      # Amount of memory in GB to allocate.
      memory_gb = resources.value.memory_gb

      # Amount of disk in GB to allocate.
      disk_gb = resources.value.disk_gb
    }
  }

  # Dynamic block for network configuration.
  dynamic "network" {
    # Create this block if network configuration is provided.
    for_each = each.value.config.flexible.network != null ? [each.value.config.flexible.network] : []

    content {
      # List of ports to forward from the VM provider to the container.
      forwarded_ports = network.value.forwarded_ports

      # Tag to apply to the instance.
      instance_tag = network.value.instance_tag

      # Google Compute Engine network where the virtual machines are created.
      name = network.value.name

      # Google Compute Engine subnetwork where the virtual machines are created.
      subnetwork = network.value.subnetwork
    }
  }

  # Dynamic block for automatic scaling settings. One of automatic_scaling or manual_scaling must be specified.
  dynamic "automatic_scaling" {
    for_each = each.value.config.flexible.automatic_scaling != null ? [each.value.config.flexible.automatic_scaling] : []
    content {
      cool_down_period        = automatic_scaling.value.cool_down_period
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      max_idle_instances      = automatic_scaling.value.max_idle_instances
      max_pending_latency     = automatic_scaling.value.max_pending_latency
      max_total_instances     = automatic_scaling.value.max_total_instances
      min_idle_instances      = automatic_scaling.value.min_idle_instances
      min_pending_latency     = automatic_scaling.value.min_pending_latency
      min_total_instances     = automatic_scaling.value.min_total_instances
      cpu_utilization {
        target_utilization = automatic_scaling.value.cpu_utilization.target_utilization
      }
      dynamic "network_utilization" {
        for_each = automatic_scaling.value.network_utilization != null ? [automatic_scaling.value.network_utilization] : []
        content {
          target_sent_bytes_per_second   = network_utilization.value.target_sent_bytes_per_second
          target_sent_packets_per_second = network_utilization.value.target_sent_packets_per_second
          target_received_bytes_per_second = network_utilization.value.target_received_bytes_per_second
          target_received_packets_per_second = network_utilization.value.target_received_packets_per_second
        }
      }
      dynamic "disk_utilization" {
        for_each = automatic_scaling.value.disk_utilization != null ? [automatic_scaling.value.disk_utilization] : []
        content {
          target_write_bytes_per_second = disk_utilization.value.target_write_bytes_per_second
          target_write_ops_per_second   = disk_utilization.value.target_write_ops_per_second
          target_read_bytes_per_second  = disk_utilization.value.target_read_bytes_per_second
          target_read_ops_per_second    = disk_utilization.value.target_read_ops_per_second
        }
      }
      dynamic "request_utilization" {
        for_each = automatic_scaling.value.request_utilization != null ? [automatic_scaling.value.request_utilization] : []
        content {
          target_request_count_per_second = request_utilization.value.target_request_count_per_second
          target_concurrent_requests      = request_utilization.value.target_concurrent_requests
        }
      }
    }
  }

  # Dynamic block for manual scaling settings. One of automatic_scaling or manual_scaling must be specified.
  dynamic "manual_scaling" {
    for_each = each.value.config.flexible.manual_scaling != null ? [each.value.config.flexible.manual_scaling] : []
    content {
      instances = manual_scaling.value.instances
    }
  }

  # Ensure the App Engine application itself exists before creating a version.
  depends_on = [google_app_engine_application.app]
}

# This resource manages the traffic split configuration for a service.
resource "google_app_engine_service_split_traffic" "main" {
  # Create a traffic split configuration for each service that defines one.
  for_each = local.traffic_splits

  # The project ID.
  project = local.project_id

  # The service to configure traffic for.
  service = each.key

  # If true, traffic migration will be gradual.
  migrate_traffic = each.value.migrate_traffic

  # The traffic split configuration block.
  split {
    # The method to split traffic by (e.g., IP, COOKIE, RANDOM).
    shard_by = each.value.shard_by

    # A map of version IDs to traffic allocation (values must sum to 1.0).
    allocations = each.value.allocations
  }

  # Ensure all versions are deployed before attempting to split traffic between them.
  depends_on = [
    google_app_engine_standard_app_version.main,
    google_app_engine_flexible_app_version.main
  ]
}
