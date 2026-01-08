output "app_id" {
  description = "The globally unique identifier for the App Engine application."
  value       = var.create_app ? google_app_engine_application.app[0].id : null
}

output "app_url" {
  description = "The default URL to access the App Engine application."
  value       = var.create_app ? "https://${google_app_engine_application.app[0].default_hostname}" : null
}

output "app_gcr_domain" {
  description = "The GCR domain used for storing instance images."
  value       = var.create_app ? google_app_engine_application.app[0].gcr_domain : null
}

output "standard_versions" {
  description = "A map of the deployed App Engine standard versions."
  value       = google_app_engine_standard_app_version.main
}

output "flexible_versions" {
  description = "A map of the deployed App Engine flexible versions."
  value       = google_app_engine_flexible_app_version.main
}

output "service_urls" {
  description = "A map of service names to their default URLs. This is only populated if `create_app` is true."
  value = var.create_app ? {
    for s_name in keys(var.services) : s_name => (
      s_name == "default"
      ? "https://${google_app_engine_application.app[0].default_hostname}"
      : "https://${s_name}-dot-${google_app_engine_application.app[0].default_hostname}"
    )
  } : {}
}
