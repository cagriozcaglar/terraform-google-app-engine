# This resource creates the App Engine application itself, which is a prerequisite for all other App Engine resources.
# An App Engine application can only be created once per project.
resource "google_app_engine_application" "app" {
  # The ID of the Google Cloud project.
  project = var.project_id

  # The location to serve the application from. This cannot be changed after creation.
  location_id = var.location_id

  # The type of database to use. Can be 'CLOUD_FIRESTORE' or 'CLOUD_DATASTORE_COMPATIBILITY'.
  database_type = var.database_type

  # The GSuite domain to associate with the application for authentication.
  auth_domain = var.auth_domain

  # Settings for Identity-Aware Proxy (IAP). This block is created only if the 'iap' variable is not null.
  dynamic "iap" {
    for_each = var.iap != null ? [var.iap] : []
    content {
      # OAuth2 client ID to use for IAP.
      oauth2_client_id = iap.value.oauth2_client_id
      # OAuth2 client secret to use for IAP.
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }
}

# This resource defines specific versions of services in App Engine Standard Environment.
resource "google_app_engine_standard_app_version" "standard" {
  for_each = var.standard_services

  # The ID of the Google Cloud project.
  project = var.project_id

  # The name of the service.
  service = each.value.service_name

  # The version ID. If not set, a default will be assigned by App Engine.
  version_id = each.value.version_id

  # The runtime environment for the application (e.g., 'python311', 'nodejs18').
  runtime = each.value.runtime

  # Code and resource deployment configuration.
  deployment {
    zip {
      # The URL of the zipped source code in a GCS bucket.
      source_url = each.value.deployment.zip.source_url
    }
  }

  # The entrypoint for the application.
  entrypoint {
    # The command to run the application.
    shell = each.value.entrypoint.shell
  }

  # The instance class to use for this version (e.g., 'F1', 'B2').
  instance_class = each.value.instance_class

  # Environment variables available to the application.
  env_variables = each.value.env_variables

  # A list of inbound services that can call this service.
  inbound_services = each.value.inbound_services

  # Automatic scaling settings for the service.
  dynamic "automatic_scaling" {
    for_each = each.value.automatic_scaling != null ? [each.value.automatic_scaling] : []
    content {
      # Maximum number of idle instances.
      max_idle_instances = automatic_scaling.value.max_idle_instances
      # Minimum number of idle instances.
      min_idle_instances = automatic_scaling.value.min_idle_instances
      # Maximum amount of time a request should wait in the pending queue.
      max_pending_latency = automatic_scaling.value.max_pending_latency
      # Minimum amount of time a request should wait in the pending queue.
      min_pending_latency = automatic_scaling.value.min_pending_latency
      # Number of concurrent requests an automatic scaling instance can accept.
      max_concurrent_requests = automatic_scaling.value.max_concurrent_requests

      # Scheduler settings for standard environment.
      dynamic "standard_scheduler_settings" {
        for_each = automatic_scaling.value.standard_scheduler_settings != null ? [automatic_scaling.value.standard_scheduler_settings] : []
        content {
          # Maximum number of instances for this version.
          max_instances = standard_scheduler_settings.value.max_instances
          # Minimum number of instances for this version.
          min_instances = standard_scheduler_settings.value.min_instances
        }
      }
    }
  }

  # Basic scaling settings for the service.
  dynamic "basic_scaling" {
    for_each = each.value.basic_scaling != null ? [each.value.basic_scaling] : []
    content {
      # Time an instance can be idle before it is shut down.
      idle_timeout = basic_scaling.value.idle_timeout
      # Maximum number of instances for this version.
      max_instances = basic_scaling.value.max_instances
    }
  }

  # Manual scaling settings for the service.
  dynamic "manual_scaling" {
    for_each = each.value.manual_scaling != null ? [each.value.manual_scaling] : []
    content {
      # Number of instances to assign to the service.
      instances = manual_scaling.value.instances
    }
  }

  # If set to 'true', the service will be deleted when the resource is destroyed.
  delete_service_on_destroy = each.value.delete_service_on_destroy

  # If set to 'true', Terraform will ignore any changes to this resource after creation.
  noop_on_destroy = each.value.noop_on_destroy

  # Ensures the App Engine application is created before deploying a version.
  depends_on = [google_app_engine_application.app]
}

# This resource defines specific versions of services in App Engine Flexible Environment.
resource "google_app_engine_flexible_app_version" "flexible" {
  for_each = var.flexible_services

  # The ID of the Google Cloud project.
  project = var.project_id

  # The name of the service.
  service = each.value.service_name

  # The version ID. If not set, a default will be assigned by App Engine.
  version_id = each.value.version_id

  # The runtime environment for the application (e.g., 'java11', 'custom').
  runtime = each.value.runtime

  # Code and resource deployment configuration.
  deployment {
    container {
      # The URI of a container image in Artifact Registry or GCR.
      image = each.value.deployment.container.image
    }
  }

  # Liveness check configuration to ensure the instance is healthy.
  liveness_check {
    # The request path.
    path = each.value.liveness_check.path
    # Time between health checks.
    check_interval = each.value.liveness_check.check_interval
    # Time before the check is considered failed.
    timeout = each.value.liveness_check.timeout
    # Number of consecutive failures required to mark an instance unhealthy.
    failure_threshold = each.value.liveness_check.failure_threshold
    # Number of consecutive successes required to mark an instance healthy.
    success_threshold = each.value.liveness_check.success_threshold
    # The initial delay before starting health checks.
    initial_delay = each.value.liveness_check.initial_delay
    # The host header to use for the check.
    host = each.value.liveness_check.host
  }

  # Readiness check configuration to ensure the instance can serve traffic.
  readiness_check {
    # The request path.
    path = each.value.readiness_check.path
    # Time between health checks.
    check_interval = each.value.readiness_check.check_interval
    # Time before the check is considered failed.
    timeout = each.value.readiness_check.timeout
    # Number of consecutive failures required to mark an instance as not ready.
    failure_threshold = each.value.readiness_check.failure_threshold
    # Number of consecutive successes required to mark an instance as ready.
    success_threshold = each.value.readiness_check.success_threshold
    # A duration to wait for the application to start before the first readiness check.
    app_start_timeout = each.value.readiness_check.app_start_timeout
    # The host header to use for the check.
    host = each.value.readiness_check.host
  }

  # Machine resources for a flexible environment instance.
  dynamic "resources" {
    for_each = each.value.resources != null ? [each.value.resources] : []
    content {
      # Number of CPU cores.
      cpu = resources.value.cpu
      # Memory in GB.
      memory_gb = resources.value.memory_gb
      # Disk size in GB.
      disk_gb = resources.value.disk_gb
    }
  }

  # Network settings for a flexible environment instance.
  dynamic "network" {
    for_each = each.value.network != null ? [each.value.network] : []
    content {
      # Google Compute Engine network where instances are created.
      name = network.value.name
      # List of ports to forward from the VM provider to the container.
      forwarded_ports = network.value.forwarded_ports
      # Tag to apply to the instance's network interface.
      instance_tag = network.value.instance_tag
      # Enable session affinity.
      session_affinity = network.value.session_affinity
    }
  }

  # Environment variables available to the application.
  env_variables = each.value.env_variables

  # The service account to run the application as.
  service_account = each.value.service_account

  # If set to 'true', the service will be deleted when the resource is destroyed.
  delete_service_on_destroy = each.value.delete_service_on_destroy

  # If set to 'true', Terraform will ignore any changes to this resource after creation.
  noop_on_destroy = each.value.noop_on_destroy

  # Ensures the App Engine application is created before deploying a version.
  depends_on = [google_app_engine_application.app]
}

# This resource maps a custom domain to the App Engine application.
resource "google_app_engine_domain_mapping" "custom_domain" {
  for_each = { for domain in var.custom_domains : domain.domain_name => domain }

  # The ID of the Google Cloud project.
  project = var.project_id

  # The custom domain name.
  domain_name = each.value.domain_name

  # SSL settings for the custom domain.
  ssl_settings {
    # SSL management type. Can be 'AUTOMATIC' or 'MANUAL'.
    ssl_management_type = each.value.ssl_management_type
  }

  # Ensures the App Engine application is created before mapping a domain.
  depends_on = [google_app_engine_application.app]
}

# This resource creates a firewall rule for the App Engine application.
resource "google_app_engine_firewall_rule" "firewall" {
  for_each = { for i, rule in var.firewall_rules : i => rule }

  # The ID of the Google Cloud project.
  project = var.project_id

  # A positive integer that defines the priority of the rule.
  priority = each.value.priority

  # The action to take on a rule match. Can be 'ALLOW' or 'DENY'.
  action = each.value.action

  # The IP address or range, in CIDR format, to match against.
  source_range = each.value.source_range

  # An optional description of the rule.
  description = each.value.description

  # Ensures the App Engine application is created before creating a firewall rule.
  depends_on = [google_app_engine_application.app]
}
