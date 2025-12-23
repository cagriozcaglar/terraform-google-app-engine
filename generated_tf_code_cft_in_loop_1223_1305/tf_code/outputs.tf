output "name" {
  description = "The full resource name of the deployed App Engine version."
  value       = local.is_enabled ? local.all_versions["this"].name : null
}

output "service" {
  description = "The name of the service the version was deployed to."
  value       = local.is_enabled ? local.all_versions["this"].service : null
}

output "version_id" {
  description = "The ID of the deployed version."
  value       = local.is_enabled ? local.all_versions["this"].version_id : null
}
