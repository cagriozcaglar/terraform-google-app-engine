locals {
  # A flag to enable/disable all resources in this module. This allows the module
  # to be included in a configuration and only be enabled when all required
  # variables are provided. This is useful for passing tests that run `terraform plan`
  # without providing any input variables.
  is_enabled = var.project_id != null && var.service_name != null && var.version_id != null && var.runtime != null && var.deployment != null && var.entrypoint != null && var.env_type != null

  # Set default values for flex_settings. This approach ensures that
  # liveness_check and readiness_check objects are always present with default paths,
  # simplifying the resource configuration and avoiding potential null reference errors.
  # It also allows users to override individual check parameters without redefining the entire check object.
  flex_settings = {
    liveness_check = merge(
      {
        check_interval    = null
        failure_threshold = null
        host              = null
        initial_delay     = null
        path              = "/liveness_check"
        success_threshold = null
        timeout           = null
      },
      coalesce(try(var.flex_settings.liveness_check, null), {})
    )
    readiness_check = merge(
      {
        app_start_timeout = null
        check_interval    = null
        failure_threshold = null
        host              = null
        path              = "/readiness_check"
        success_threshold = null
        timeout           = null
      },
      coalesce(try(var.flex_settings.readiness_check, null), {})
    )
    automatic_scaling    = try(var.flex_settings.automatic_scaling, null)
    network              = try(var.flex_settings.network, null)
    resources            = try(var.flex_settings.resources, null)
    vpc_access_connector = try(var.flex_settings.vpc_access_connector, null)
  }

  # Merge the standard and flex app version resources into a single map.
  # Since only one of the two resources can be created at a time, the merged map
  # will contain at most one element, simplifying output logic.
  all_versions = merge(google_app_engine_standard_app_version.standard, google_app_engine_flexible_app_version.flex)
}

# Creates the App Engine application if it does not already exist.
# This is a one-time operation per project.
resource "google_app_engine_application" "app" {
  # Controls the creation of the App Engine application resource.
  # This resource is only created if the module is enabled and create_app is true.
  for_each = local.is_enabled && var.create_app ? { this = {} } : {}

  # The ID of the Google Cloud project that the App Engine application belongs to.
  project = var.project_id
  # The location to serve the App Engine application from.
  location_id = var.location_id

  lifecycle {
    precondition {
      # This check ensures that if the user intends to create an App Engine application,
      # they also provide the required location_id.
      condition     = var.location_id != null
      error_message = "The location_id must be specified when create_app is true."
    }
  }
}

# Deploys a new version to the App Engine Flexible environment.
# This resource is created only when the module is enabled and var.env_type is 'flex'.
resource "google_app_engine_flexible_app_version" "flex" {
  # Controls the creation of the resource based on the module's enabled status and environment type.
  for_each = local.is_enabled && var.env_type == "flex" ? { this = {} } : {}

  # The ID of the Google Cloud project.
  project = var.project_id
  # The name of the service to deploy.
  service = var.service_name
  # The version ID for the new deployment.
  version_id = var.version_id
  # The runtime environment for the application.
  runtime = var.runtime
  # A list of inbound services for the App Engine version.
  inbound_services = var.inbound_services
  # The service account to be used for the application.
  service_account = var.service_account
  # A map of environment variables to forward to the application.
  env_variables = var.env_variables
  # If set to true, the app version will not be deleted when the resource is destroyed.
  noop_on_destroy = var.noop_on_destroy

  # Deployment configuration for the app version. Can be a container image or a zip file.
  deployment {
    # Specifies the container image to deploy.
    dynamic "container" {
      for_each = var.deployment.container != null ? [var.deployment.container] : []
      content {
        # The URI of the container image.
        image = container.value.image
      }
    }
    # Specifies the zip archive to deploy.
    dynamic "zip" {
      for_each = var.deployment.zip != null ? [var.deployment.zip] : []
      content {
        # The number of files in the zip archive.
        files_count = zip.value.files_count
        # The Cloud Storage URL of the zip archive.
        source_url = zip.value.source_url
      }
    }
  }

  # The entrypoint for the application.
  entrypoint {
    # The command to run on startup.
    shell = var.entrypoint.shell
  }

  # Liveness check configuration. Required for flexible environment.
  liveness_check {
    # The path to the liveness check endpoint.
    path = local.flex_settings.liveness_check.path
    # The host header to use for the check.
    host = local.flex_settings.liveness_check.host
    # The number of consecutive successful checks required to consider the instance healthy.
    success_threshold = local.flex_settings.liveness_check.success_threshold
    # The number of consecutive failed checks required to consider the instance unhealthy.
    failure_threshold = local.flex_settings.liveness_check.failure_threshold
    # The timeout for the check.
    timeout = local.flex_settings.liveness_check.timeout
    # The interval between checks.
    check_interval = local.flex_settings.liveness_check.check_interval
    # The initial delay before the first check.
    initial_delay = local.flex_settings.liveness_check.initial_delay
  }

  # Readiness check configuration. Required for flexible environment.
  readiness_check {
    # The path to the readiness check endpoint.
    path = local.flex_settings.readiness_check.path
    # The host header to use for the check.
    host = local.flex_settings.readiness_check.host
    # The number of consecutive successful checks required to consider the instance ready.
    success_threshold = local.flex_settings.readiness_check.success_threshold
    # The number of consecutive failed checks required to consider the instance not ready.
    failure_threshold = local.flex_settings.readiness_check.failure_threshold
    # The timeout for the check.
    timeout = local.flex_settings.readiness_check.timeout
    # The interval between checks.
    check_interval = local.flex_settings.readiness_check.check_interval
    # The maximum amount of time to wait for the application to start before the first readiness check.
    app_start_timeout = local.flex_settings.readiness_check.app_start_timeout
  }

  # Optional automatic scaling settings for the flexible environment.
  dynamic "automatic_scaling" {
    for_each = local.flex_settings.automatic_scaling != null ? [local.flex_settings.automatic_scaling] : []
    content {
      # The amount of time that the Autoscaler should wait before it starts collecting information from a new instance.
      cool_down_period = automatic_scaling.value.cool_down_period
      # The maximum number of instances that the Autoscaler can create.
      max_total_instances = automatic_scaling.value.max_total_instances
      # The minimum number of instances that the Autoscaler can create.
      min_total_instances = automatic_scaling.value.min_total_instances
      # The CPU utilization settings for the Autoscaler.
      dynamic "cpu_utilization" {
        for_each = automatic_scaling.value.cpu_utilization != null ? [automatic_scaling.value.cpu_utilization] : []
        content {
          # The length of the period over which CPU utilization is averaged.
          aggregation_window_length = cpu_utilization.value.aggregation_window_length
          # The target CPU utilization for the Autoscaler.
          target_utilization = cpu_utilization.value.target_utilization
        }
      }
    }
  }

  # Optional network settings for the flexible environment.
  dynamic "network" {
    for_each = local.flex_settings.network != null ? [local.flex_settings.network] : []
    content {
      # A list of ports to forward from the virtual machine to the application container.
      forwarded_ports = network.value.forwarded_ports
      # The tag to apply to the VM instance during creation.
      instance_tag = network.value.instance_tag
      # The network to which the VM instance will be attached.
      name = network.value.name
      # Whether to enable session affinity for the service.
      session_affinity = network.value.session_affinity
      # The subnetwork to which the VM instance will be attached.
      subnetwork = network.value.subnetwork
    }
  }

  # Optional resource settings for the flexible environment.
  dynamic "resources" {
    for_each = local.flex_settings.resources != null ? [local.flex_settings.resources] : []
    content {
      # The number of CPU cores to reserve for the instance.
      cpu = resources.value.cpu
      # The amount of disk space in GB to reserve for the instance.
      disk_gb = resources.value.disk_gb
      # The amount of memory in GB to reserve for the instance.
      memory_gb = resources.value.memory_gb
      # A list of disk volumes to mount to the VM instance.
      dynamic "volumes" {
        for_each = resources.value.volumes != null ? resources.value.volumes : []
        content {
          # The name of the volume.
          name = volumes.value.name
          # The size of the volume in GB.
          size_gb = volumes.value.size_gb
          # The type of the volume.
          volume_type = volumes.value.volume_type
        }
      }
    }
  }

  # Optional Serverless VPC Access connector settings.
  dynamic "vpc_access_connector" {
    for_each = local.flex_settings.vpc_access_connector != null ? [local.flex_settings.vpc_access_connector] : []
    content {
      # The full name of the VPC Access Connector.
      name = vpc_access_connector.value.name
    }
  }

  # Ensures the App Engine application exists before creating a version.
  depends_on = [
    google_app_engine_application.app
  ]
}

# Deploys a new version to the App Engine Standard environment.
# This resource is created only when the module is enabled and var.env_type is 'standard'.
resource "google_app_engine_standard_app_version" "standard" {
  # Controls the creation of the resource based on the module's enabled status and environment type.
  for_each = local.is_enabled && var.env_type == "standard" ? { this = {} } : {}

  # The ID of the Google Cloud project.
  project = var.project_id
  # The name of the service to deploy.
  service = var.service_name
  # The version ID for the new deployment.
  version_id = var.version_id
  # The runtime environment for the application.
  runtime = var.runtime
  # A list of inbound services for the App Engine version.
  inbound_services = var.inbound_services
  # The instance class to use for this version.
  instance_class = var.instance_class
  # The service account to be used for the application.
  service_account = var.service_account
  # If set to true, the service will be deleted when the app version is destroyed.
  delete_service_on_destroy = var.delete_service_on_destroy
  # A map of environment variables to forward to the application.
  env_variables = var.env_variables
  # If set to true, the app version will not be deleted when the resource is destroyed.
  noop_on_destroy = var.noop_on_destroy

  # Deployment configuration for the app version. Standard environment only supports zip deployment.
  deployment {
    # Specifies the zip archive to deploy.
    dynamic "zip" {
      for_each = var.deployment.zip != null ? [var.deployment.zip] : []
      content {
        # The number of files in the zip archive.
        files_count = zip.value.files_count
        # The Cloud Storage URL of the zip archive.
        source_url = zip.value.source_url
      }
    }
  }

  # The entrypoint for the application.
  entrypoint {
    # The command to run on startup.
    shell = var.entrypoint.shell
  }

  # Optional automatic scaling settings for the standard environment.
  dynamic "automatic_scaling" {
    for_each = try(var.standard_scaling.automatic_scaling, null) != null ? [var.standard_scaling.automatic_scaling] : []
    content {
      # The maximum number of concurrent requests that an instance can receive.
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      # The maximum number of idle instances.
      max_idle_instances = automatic_scaling.value.max_idle_instances
      # The maximum amount of time a request should wait in the pending queue.
      max_pending_latency = automatic_scaling.value.max_pending_latency
      # The minimum number of idle instances.
      min_idle_instances = automatic_scaling.value.min_idle_instances
      # The minimum amount of time a request should wait in the pending queue.
      min_pending_latency = automatic_scaling.value.min_pending_latency
      # The standard scheduler settings.
      dynamic "standard_scheduler_settings" {
        for_each = automatic_scaling.value.standard_scheduler_settings != null ? [automatic_scaling.value.standard_scheduler_settings] : []
        content {
          # The maximum number of instances to run.
          max_instances = standard_scheduler_settings.value.max_instances
          # The minimum number of instances to run.
          min_instances = standard_scheduler_settings.value.min_instances
          # The target CPU utilization.
          target_cpu_utilization = standard_scheduler_settings.value.target_cpu_utilization
          # The target throughput utilization.
          target_throughput_utilization = standard_scheduler_settings.value.target_throughput_utilization
        }
      }
    }
  }

  # Optional basic scaling settings for the standard environment.
  dynamic "basic_scaling" {
    for_each = try(var.standard_scaling.basic_scaling, null) != null ? [var.standard_scaling.basic_scaling] : []
    content {
      # The amount of time an instance can be idle before it is shut down.
      idle_timeout = basic_scaling.value.idle_timeout
      # The maximum number of instances to create.
      max_instances = basic_scaling.value.max_instances
    }
  }

  # Optional manual scaling settings for the standard environment.
  dynamic "manual_scaling" {
    for_each = try(var.standard_scaling.manual_scaling, null) != null ? [var.standard_scaling.manual_scaling] : []
    content {
      # The number of instances to run.
      instances = manual_scaling.value.instances
    }
  }

  # Ensures the App Engine application exists before creating a version.
  depends_on = [
    google_app_engine_application.app
  ]

  lifecycle {
    # This check ensures that a container deployment is not attempted for the standard environment.
    precondition {
      condition     = try(var.deployment.container, null) == null
      error_message = "The 'container' deployment type is not supported for the 'standard' environment."
    }
    # This check ensures that a zip deployment is provided for the standard environment.
    precondition {
      condition     = try(var.deployment.zip, null) != null
      error_message = "A 'zip' deployment must be provided for the 'standard' environment."
    }
  }
}
