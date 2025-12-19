#
# This resource creates the App Engine application, which is a top-level resource
# required before any services or versions can be deployed. It is a one-time
# setup for a given project and location.
#
resource "google_app_engine_application" "app" {
  # The number of instances of this resource to create.
  # It is set to 1 if `var.create_app` is true and required variables are provided, otherwise 0.
  count = local.enabled && var.create_app ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The location to serve the application from.
  location_id = var.location_id
  # The domain to authenticate users with using Google Accounts.
  auth_domain = var.auth_domain

  #
  # This block configures Identity-Aware Proxy for the application.
  #
  dynamic "iap" {
    # Iterates over a collection to generate nested blocks.
    # It creates the block only if `var.iap_config` is not null.
    for_each = var.iap_config != null ? [var.iap_config] : []

    # The content of the generated nested block.
    content {
      # Whether the serving infrastructure will authenticate and authorize all incoming requests.
      enabled = iap.value.enabled
      # OAuth2 client ID to use for the authentication flow.
      oauth2_client_id = iap.value.oauth2_client_id
      # OAuth2 client secret to use for the authentication flow.
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }
}

#
# This resource deploys a new version to a service in the App Engine Standard Environment.
# It is created only when `var.environment_type` is set to "standard".
#
resource "google_app_engine_standard_app_version" "standard" {
  # The number of instances of this resource to create.
  # It is set to 1 if `var.environment_type` is "standard" and required variables are provided, otherwise 0.
  count = local.enabled && var.environment_type == "standard" ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The name of the service to deploy the version to.
  service = var.service_name
  # A unique identifier for this version.
  version_id = var.version_id
  # The runtime environment for this version.
  runtime = var.runtime
  # The instance class to use for this version.
  instance_class = var.instance_class
  # The service account to run the version as.
  service_account = var.service_account
  # Do not delete the version when this resource is destroyed.
  noop_on_destroy = var.noop_on_destroy
  # A list of inbound services allowed to connect.
  inbound_services = var.inbound_services
  # Environment variables available to the application.
  env_variables = var.env_variables

  #
  # Specifies the command to run on instance startup.
  #
  dynamic "entrypoint" {
    # Creates the block only if `var.entrypoint` is not null.
    for_each = var.entrypoint != null ? [var.entrypoint] : []

    # The content of the generated nested block.
    content {
      # The format of the entrypoint, e.g., a shell command.
      shell = entrypoint.value.shell
    }
  }

  #
  # Configures the source code for the deployment.
  #
  deployment {
    #
    # Specifies a zip archive as the source.
    #
    zip {
      # The Google Cloud Storage URL of the zip archive.
      source_url = var.deployment.zip.source_url
    }
  }

  #
  # Configures automatic scaling settings.
  #
  dynamic "automatic_scaling" {
    # Creates the block only if `var.standard_automatic_scaling` is not null.
    for_each = var.standard_automatic_scaling != null ? [var.standard_automatic_scaling] : []

    # The content of the generated nested block.
    content {
      # Minimum number of idle instances.
      min_idle_instances = automatic_scaling.value.min_idle_instances
      # Maximum number of idle instances.
      max_idle_instances = automatic_scaling.value.max_idle_instances
      # Minimum pending latency.
      min_pending_latency = automatic_scaling.value.min_pending_latency
      # Maximum pending latency.
      max_pending_latency = automatic_scaling.value.max_pending_latency
      # Maximum number of concurrent requests an instance can accept.
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests

      #
      # Scheduler settings for standard environment.
      #
      dynamic "standard_scheduler_settings" {
        # Creates the block only if `standard_scheduler_settings` is not null.
        for_each = automatic_scaling.value.standard_scheduler_settings != null ? [automatic_scaling.value.standard_scheduler_settings] : []

        # The content of the generated nested block.
        content {
          # Minimum number of instances to run.
          min_instances = standard_scheduler_settings.value.min_instances
          # Maximum number of instances to run.
          max_instances = standard_scheduler_settings.value.max_instances
          # Target CPU utilization ratio.
          target_cpu_utilization = standard_scheduler_settings.value.target_cpu_utilization
          # Target throughput utilization ratio.
          target_throughput_utilization = standard_scheduler_settings.value.target_throughput_utilization
        }
      }
    }
  }

  #
  # Configures basic scaling settings.
  #
  dynamic "basic_scaling" {
    # Creates the block only if `var.standard_basic_scaling` is not null.
    for_each = var.standard_basic_scaling != null ? [var.standard_basic_scaling] : []

    # The content of the generated nested block.
    content {
      # Maximum number of instances to create for this version.
      max_instances = basic_scaling.value.max_instances
      # Time that an instance can be idle before it is shut down.
      idle_timeout = basic_scaling.value.idle_timeout
    }
  }

  #
  # Configures manual scaling settings.
  #
  dynamic "manual_scaling" {
    # Creates the block only if `var.standard_manual_scaling` is not null.
    for_each = var.standard_manual_scaling != null ? [var.standard_manual_scaling] : []

    # The content of the generated nested block.
    content {
      # Number of instances to assign to the service.
      instances = manual_scaling.value.instances
    }
  }

  # Ensures the App Engine application exists before deploying a version.
  depends_on = [google_app_engine_application.app]

  lifecycle {
    # Ensures that scaling configurations are not mutually exclusive.
    precondition {
      condition     = local.standard_scaling_count <= 1
      error_message = "Only one of standard_automatic_scaling, standard_basic_scaling, or standard_manual_scaling can be configured."
    }
    # Ensures the correct deployment source is provided for the standard environment.
    precondition {
      condition     = var.deployment != null && var.deployment.zip != null && var.deployment.container == null
      error_message = "For a 'standard' environment, the 'deployment' variable must be set, its 'zip' attribute must be configured, and its 'container' attribute must be null."
    }
  }
}

#
# This resource deploys a new version to a service in the App Engine Flexible Environment.
# It is created only when `var.environment_type` is set to "flexible".
#
resource "google_app_engine_flexible_app_version" "flexible" {
  # The number of instances of this resource to create.
  # It is set to 1 if `var.environment_type` is "flexible" and required variables are provided, otherwise 0.
  count = local.enabled && var.environment_type == "flexible" ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The name of the service to deploy the version to.
  service = var.service_name
  # A unique identifier for this version.
  version_id = var.version_id
  # The runtime environment for this version, typically 'custom' for containers.
  runtime = var.runtime
  # The service account to run the version as.
  service_account = var.service_account
  # Do not delete the version when this resource is destroyed.
  noop_on_destroy = var.noop_on_destroy
  # Environment variables available to the application.
  env_variables = var.env_variables

  #
  # Configures the source for the deployment, which is a container for flexible env.
  #
  deployment {
    #
    # Specifies a container image as the source.
    #
    container {
      # The full URL of the container image.
      image = var.deployment.container.image
    }
  }

  #
  # Health check for instance health.
  #
  dynamic "liveness_check" {
    # Creates the block only if `var.liveness_check` is not null.
    for_each = var.liveness_check != null ? [var.liveness_check] : []

    # The content of the generated nested block.
    content {
      # The request path.
      path = liveness_check.value.path
      # Time interval between checks.
      check_interval = liveness_check.value.check_interval
      # Time limit for a health check.
      timeout = liveness_check.value.timeout
      # Number of consecutive failed checks required before considering an instance unhealthy.
      failure_threshold = liveness_check.value.failure_threshold
      # Number of consecutive successful checks required before considering an instance healthy.
      success_threshold = liveness_check.value.success_threshold
      # Host header to send when performing a check.
      host = liveness_check.value.host
      # The initial delay before starting to execute the checks.
      initial_delay = liveness_check.value.initial_delay
    }
  }

  #
  # Health check for instance readiness to serve traffic.
  #
  dynamic "readiness_check" {
    # Creates the block only if `var.readiness_check` is not null.
    for_each = var.readiness_check != null ? [var.readiness_check] : []

    # The content of the generated nested block.
    content {
      # The request path.
      path = readiness_check.value.path
      # Time interval between checks.
      check_interval = readiness_check.value.check_interval
      # Time limit for a health check.
      timeout = readiness_check.value.timeout
      # Number of consecutive failed checks required before considering an instance unhealthy.
      failure_threshold = readiness_check.value.failure_threshold
      # Number of consecutive successful checks required before considering an instance healthy.
      success_threshold = readiness_check.value.success_threshold
      # Host header to send when performing a check.
      host = readiness_check.value.host
      # A duration to wait for the application to start before declaring it healthy.
      app_start_timeout = readiness_check.value.app_start_timeout
    }
  }

  #
  # Configures machine resources for the instances.
  #
  dynamic "resources" {
    # Creates the block only if `var.resources` is not null.
    for_each = var.resources != null ? [var.resources] : []

    # The content of the generated nested block.
    content {
      # Number of CPU cores.
      cpu = resources.value.cpu
      # Memory in GB.
      memory_gb = resources.value.memory_gb
      # Disk size in GB.
      disk_gb = resources.value.disk_gb

      #
      # List of volumes to mount.
      #
      dynamic "volumes" {
        # Creates a block for each volume specified.
        for_each = resources.value.volumes != null ? resources.value.volumes : []
        # The content of the generated nested block.
        content {
          # Unique name for the volume.
          name = volumes.value.name
          # Type of the volume.
          volume_type = volumes.value.volume_type
          # Volume size in GB.
          size_gb = volumes.value.size_gb
        }
      }
    }
  }

  #
  # Configures network settings for the instances.
  #
  dynamic "network" {
    # Creates the block only if `var.network` is not null.
    for_each = var.network != null ? [var.network] : []

    # The content of the generated nested block.
    content {
      # List of ports to forward from the VM provider to the container.
      forwarded_ports = network.value.forwarded_ports
      # Tag to apply to the instance.
      instance_tag = network.value.instance_tag
      # The name of the virtual network to use.
      name = network.value.name
      # Enable session affinity.
      session_affinity = network.value.session_affinity
      # Google Cloud subnetwork to use.
      subnetwork = network.value.subnetwork
    }
  }

  #
  # Configures automatic scaling settings for the flexible environment.
  #
  dynamic "automatic_scaling" {
    # Creates the block only if `var.flexible_automatic_scaling` is not null.
    for_each = var.flexible_automatic_scaling != null ? [var.flexible_automatic_scaling] : []

    # The content of the generated nested block.
    content {
      # The time period that the Autoscaler should wait before it starts collecting information from a new instance.
      cool_down_period = automatic_scaling.value.cool_down_period
      # Maximum number of instances that can be created for this version.
      max_total_instances = automatic_scaling.value.max_total_instances
      # Minimum number of instances that can be created for this version.
      min_total_instances = automatic_scaling.value.min_total_instances
      # Number of concurrent requests an automatic scaling instance can accept before the scheduler spawns a new instance.
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests
      # Maximum amount of time that a request should wait in the pending queue before starting a new instance to handle it.
      max_pending_latency = automatic_scaling.value.max_pending_latency
      # Minimum amount of time that a request should wait in the pending queue before starting a new instance to handle it.
      min_pending_latency = automatic_scaling.value.min_pending_latency

      #
      # Target CPU utilization ratio to maintain when scaling.
      #
      cpu_utilization {
        # Period of time over which CPU utilization is calculated.
        target_utilization = automatic_scaling.value.cpu_utilization.target_utilization
      }

      #
      # Target requests per second.
      #
      dynamic "request_utilization" {
        # Creates the block only if `request_utilization` is not null.
        for_each = automatic_scaling.value.request_utilization != null ? [automatic_scaling.value.request_utilization] : []
        # The content of the generated nested block.
        content {
          # Target requests per second.
          target_request_count_per_second = request_utilization.value.target_request_count_per_second
          # Target number of concurrent requests.
          target_concurrent_requests = request_utilization.value.target_concurrent_requests
        }
      }

      #
      # Target disk utilization ratio to maintain when scaling.
      #
      dynamic "disk_utilization" {
        # Creates the block only if `disk_utilization` is not null.
        for_each = automatic_scaling.value.disk_utilization != null ? [automatic_scaling.value.disk_utilization] : []
        # The content of the generated nested block.
        content {
          # Target bytes written per second.
          target_write_bytes_per_second = disk_utilization.value.target_write_bytes_per_second
          # Target ops written per second.
          target_write_ops_per_second = disk_utilization.value.target_write_ops_per_second
          # Target bytes read per second.
          target_read_bytes_per_second = disk_utilization.value.target_read_bytes_per_second
          # Target ops read per second.
          target_read_ops_per_second = disk_utilization.value.target_read_ops_per_second
        }
      }

      #
      # Target network utilization ratio to maintain when scaling.
      #
      dynamic "network_utilization" {
        # Creates the block only if `network_utilization` is not null.
        for_each = automatic_scaling.value.network_utilization != null ? [automatic_scaling.value.network_utilization] : []
        # The content of the generated nested block.
        content {
          # Target bytes sent per second.
          target_sent_bytes_per_second = network_utilization.value.target_sent_bytes_per_second
          # Target packets sent per second.
          target_sent_packets_per_second = network_utilization.value.target_sent_packets_per_second
          # Target bytes received per second.
          target_received_bytes_per_second = network_utilization.value.target_received_bytes_per_second
          # Target packets received per second.
          target_received_packets_per_second = network_utilization.value.target_received_packets_per_second
        }
      }
    }
  }

  #
  # Configures manual scaling settings for the flexible environment.
  #
  dynamic "manual_scaling" {
    # Creates the block only if `var.flexible_manual_scaling` is not null.
    for_each = var.flexible_manual_scaling != null ? [var.flexible_manual_scaling] : []

    # The content of the generated nested block.
    content {
      # Number of instances to assign to the service.
      instances = manual_scaling.value.instances
    }
  }

  # Ensures the App Engine application exists before deploying a version.
  depends_on = [google_app_engine_application.app]

  lifecycle {
    # The flexible environment requires exactly one scaling configuration to serve traffic.
    precondition {
      condition     = local.flexible_scaling_count == 1
      error_message = "Exactly one of flexible_automatic_scaling or flexible_manual_scaling must be configured for the flexible environment."
    }
    # Ensures the correct deployment source is provided for the flexible environment.
    precondition {
      condition     = var.deployment != null && var.deployment.container != null && var.deployment.zip == null
      error_message = "For a 'flexible' environment, the 'deployment' variable must be set, its 'container' attribute must be configured, and its 'zip' attribute must be null."
    }
  }
}

#
# This resource manages traffic splitting for an App Engine service, allowing for
# gradual rollouts and canary deployments. It is created if `var.traffic_split`
# is configured, or if `var.promote` is true.
#
resource "google_app_engine_service_split_traffic" "split" {
  # The number of instances of this resource to create.
  # Create this resource if a custom traffic split is defined, or if automatic promotion is enabled,
  # a version was actually deployed, and required variables are provided.
  count = local.enabled && (var.traffic_split != null || var.promote) && local.deployed_version_id != null ? 1 : 0

  # The ID of the project in which the resource belongs.
  project = var.project_id
  # The name of the service to manage traffic for.
  service = var.service_name
  # If true, all traffic is migrated to the new version. Must be false when `split` is specified.
  migrate_traffic = false

  #
  # Defines how traffic is allocated across different versions.
  #
  split {
    # Method used to shard traffic (e.g., 'COOKIE', 'IP', 'RANDOM').
    shard_by = var.traffic_split != null ? var.traffic_split.shard_by : "COOKIE"
    # A map where keys are version IDs and values are traffic allocation percentages (0.0 to 1.0).
    # If a custom split is provided, use it. Otherwise, if promoting, send 100% to the new version.
    allocations = var.traffic_split != null ? var.traffic_split.allocations : {
      (local.deployed_version_id) = 1.0
    }
  }

  # Ensures the versions to split traffic between are deployed first.
  depends_on = [
    google_app_engine_standard_app_version.standard,
    google_app_engine_flexible_app_version.flexible
  ]
}

locals {
  # Conditional to enable/disable resource creation based on required inputs.
  enabled = var.project_id != null && var.location_id != null && var.runtime != null && var.deployment != null

  # Count how many standard scaling configurations are provided.
  standard_scaling_count = length([
    for config in [var.standard_automatic_scaling, var.standard_basic_scaling, var.standard_manual_scaling] : config if config != null
  ])

  # Count how many flexible scaling configurations are provided.
  flexible_scaling_count = length([
    for config in [var.flexible_automatic_scaling, var.flexible_manual_scaling] : config if config != null
  ])

  # Determine the ID of the version that was just deployed.
  deployed_version_id = one(compact([
    try(google_app_engine_standard_app_version.standard[0].version_id, null),
    try(google_app_engine_flexible_app_version.flexible[0].version_id, null)
  ]))

  # Determine the name of the version that was just deployed.
  deployed_version_name = one(compact([
    try(google_app_engine_standard_app_version.standard[0].name, null),
    try(google_app_engine_flexible_app_version.flexible[0].name, null)
  ]))
}
