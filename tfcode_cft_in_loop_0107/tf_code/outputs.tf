output "app_engine_application_name" {
  description = "The name of the App Engine application."
  value       = local.app_enabled ? google_app_engine_application.app[0].name : null
}

output "service_name" {
  description = "The name of the App Engine service."
  value       = var.service_name
}

output "version_id" {
  description = "The ID of the deployed App Engine version."
  value       = local.version_enabled ? local.version.version_id : null
}

output "version_url" {
  description = "The URL to access the deployed version."
  value       = local.version_enabled ? "https://${local.version.version_id}-dot-${var.service_name}-dot-${google_app_engine_application.app[0].default_hostname}" : null
}
