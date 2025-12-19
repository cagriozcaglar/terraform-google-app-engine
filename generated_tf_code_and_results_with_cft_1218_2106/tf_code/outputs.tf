output "app_engine_application_id" {
  description = "The unique ID of the App Engine application."
  value       = try(google_app_engine_application.app[0].id, null)
}

output "app_engine_application_url" {
  description = "The default URL to access the App Engine application."
  value       = try(format("https://%s", google_app_engine_application.app[0].default_hostname), null)
}

output "service" {
  description = "The name of the App Engine service where the version was deployed."
  value       = var.service_name
}

output "version_id" {
  description = "The unique identifier for the deployed version."
  value       = local.deployed_version_id
}

output "version_name" {
  description = "The full name of the deployed App Engine version."
  value       = local.deployed_version_name
}
