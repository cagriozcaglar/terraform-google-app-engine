# This file contains the resource definitions for the Terraform module.
locals {
  # Consolidate project ID logic to be used across resources.
  # If the App Engine application is created by this module, its project attribute is used.
  # Otherwise, the provided project_id variable is used.
  project = var.create_app ? one(google_app_engine_application.app[*].project) : var.project_id
}

# The App Engine application resource, which must be created once per project.
# Its creation is controlled by the `create_app` variable.
resource "google_app_engine_application" "app" {
  # The number of instances of this resource to create.
  # It's set to 1 if `var.create_app` is true, otherwise 0.
  count = var.create_app ? 1 : 0

  # The ID of the project in which the resource belongs. If not provided, the provider project is used.
  project = var.project_id

  # The location to serve the application from.
  location_id = var.location_id

  # The type of database to use.
  database_type = var.database_type

  # The serving status of the application.
  serving_status = var.serving_status
}

# Deploys one or more versions for specified services within the App Engine application.
# It iterates over the `var.services` map to create a version for each entry.
resource "google_app_engine_standard_app_version" "main" {
  # Create a resource for each service defined in the `var.services` map.
  for_each = var.services

  # The ID of the project in which the resource belongs.
  project = local.project

  # The name of the service to which this version belongs.
  service = each.key

  # The version ID.
  version_id = each.value.version_id

  # The runtime environment for the application.
  runtime = each.value.runtime

  # The instance class to use for this version.
  instance_class = each.value.instance_class

  # A map of environment variables available to the application.
  env_variables = each.value.env_variables

  # A list of inbound services that can access this version.
  inbound_services = each.value.inbound_services

  # If set to true, deleting this resource will no-op (the version will be preserved).
  noop_on_destroy = each.value.noop_on_destroy

  # Code and application artifacts that make up this version.
  deployment {
    # The zip file containing the source code.
    zip {
      # The GCS URL of the zip file.
      source_url = each.value.deployment.zip.source_url
    }
  }

  # The command to run the application.
  entrypoint {
    # The shell command to execute.
    shell = each.value.entrypoint.shell
  }

  # Dynamic block for automatic scaling settings.
  # This block is only included if `each.value.automatic_scaling` is not null.
  dynamic "automatic_scaling" {
    # Iterate over the automatic_scaling object if it's not null.
    for_each = each.value.automatic_scaling != null ? [each.value.automatic_scaling] : []
    content {
      # Minimum number of idle instances that should be maintained for this version.
      min_idle_instances = lookup(automatic_scaling.value, "min_idle_instances", null)
      # Maximum number of idle instances that should be maintained for this version.
      max_idle_instances = lookup(automatic_scaling.value, "max_idle_instances", null)
      # Minimum amount of time a request should wait in the pending queue before starting a new instance to handle it.
      min_pending_latency = lookup(automatic_scaling.value, "min_pending_latency", null)
      # Maximum amount of time a request should wait in the pending queue before starting a new instance to handle it.
      max_pending_latency = lookup(automatic_scaling.value, "max_pending_latency", null)
      # Number of concurrent requests an instance can accept before the scheduler spawns a new instance.
      max_concurrent_requests = lookup(automatic_scaling.value, "max_concurrent_requests", null)

      # Dynamic block for standard scheduler settings.
      # This block is only included if any of its nested attributes are defined in the input.
      dynamic "standard_scheduler_settings" {
        # Check if any of the scheduler-specific settings are provided.
        for_each = (lookup(automatic_scaling.value, "min_instances", null) != null ||
          lookup(automatic_scaling.value, "max_instances", null) != null ||
          lookup(automatic_scaling.value, "target_cpu_utilization", null) != null ||
        lookup(automatic_scaling.value, "target_throughput_utilization", null) != null) ? [1] : []

        content {
          # Minimum number of instances that must be running for this version.
          min_instances = lookup(automatic_scaling.value, "min_instances", null)
          # Maximum number of instances that can be created for this version.
          max_instances = lookup(automatic_scaling.value, "max_instances", null)
          # Target CPU utilization ratio to maintain when scaling.
          target_cpu_utilization = lookup(automatic_scaling.value, "target_cpu_utilization", null)
          # Target throughput utilization ratio to maintain when scaling.
          target_throughput_utilization = lookup(automatic_scaling.value, "target_throughput_utilization", null)
        }
      }
    }
  }

  # Dynamic block for basic scaling settings.
  # This block is only included if `each.value.basic_scaling` is not null.
  dynamic "basic_scaling" {
    # Iterate over the basic_scaling object if it's not null.
    for_each = each.value.basic_scaling != null ? [each.value.basic_scaling] : []
    content {
      # Maximum number of instances to create for this version.
      max_instances = basic_scaling.value.max_instances
      # Time that an instance can be idle before it is shut down.
      idle_timeout = lookup(basic_scaling.value, "idle_timeout", null)
    }
  }

  # Dynamic block for manual scaling settings.
  # This block is only included if `each.value.manual_scaling` is not null.
  dynamic "manual_scaling" {
    # Iterate over the manual_scaling object if it's not null.
    for_each = each.value.manual_scaling != null ? [each.value.manual_scaling] : []
    content {
      # The number of instances to allocate to the service.
      instances = manual_scaling.value.instances
    }
  }

  # Ensures the App Engine application exists before trying to deploy a version.
  depends_on = [google_app_engine_application.app]
}

# Manages the traffic split for services that have a `traffic_split` configuration.
resource "google_app_engine_service_split_traffic" "split" {
  # Create a resource only for services that have a `traffic_split` block defined.
  for_each = { for k, v in var.services : k => v if v.traffic_split != null }

  # The ID of the project in which the resource belongs.
  project = local.project

  # The name of the service to which this traffic split belongs.
  service = each.key

  # If set to true, migrating traffic is performed gradually.
  migrate_traffic = each.value.traffic_split.migrate_traffic

  # Traffic splitting configuration.
  split {
    # The method used to shard traffic.
    shard_by = each.value.traffic_split.shard_by

    # A map of version IDs to the percentage of traffic they should receive.
    allocations = each.value.traffic_split.allocations
  }

  # Ensures all service versions are created before attempting to configure traffic splitting.
  depends_on = [google_app_engine_standard_app_version.main]
}

# Manages custom domain mappings for the App Engine application.
resource "google_app_engine_domain_mapping" "domains" {
  # Create a resource for each domain mapping defined in `var.domain_mappings`.
  for_each = { for domain in var.domain_mappings : domain.domain_name => domain }

  # The ID of the project in which the resource belongs.
  project = local.project

  # The custom domain name to map.
  domain_name = each.key

  # SSL settings for the custom domain.
  ssl_settings {
    # SSL management type.
    ssl_management_type = each.value.ssl_management_type
    # The ID of the managed SSL certificate.
    certificate_id = each.value.certificate_id
  }

  # Ensures the App Engine application exists before trying to map a domain.
  depends_on = [google_app_engine_application.app]
}
