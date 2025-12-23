output "id" {
  description = "The full resource ID of the App Engine application."
  value       = google_app_engine_application.app.id
}

output "name" {
  description = "The name of the App Engine application, which is the project ID."
  value       = google_app_engine_application.app.name
}

output "url_dispatch_rules" {
  description = "The URL dispatch rules for the application, as a list of maps."
  value       = google_app_engine_application.app.url_dispatch_rule
}

output "default_hostname" {
  description = "The default hostname for this application."
  value       = google_app_engine_application.app.default_hostname
}

output "gcr_domain" {
  description = "The GCR domain used for storing managed Docker images for this app."
  value       = google_app_engine_application.app.gcr_domain
}

output "standard_services" {
  description = "A map of the deployed App Engine Standard services and their attributes."
  value       = google_app_engine_standard_app_version.standard
}

output "flexible_services" {
  description = "A map of the deployed App Engine Flexible services and their attributes."
  value       = google_app_engine_flexible_app_version.flexible
}

output "domain_mappings" {
  description = "A map of the configured custom domain mappings."
  value       = google_app_engine_domain_mapping.custom_domain
}

output "firewall_rules" {
  description = "A map of the configured firewall rules."
  value       = google_app_engine_firewall_rule.firewall
}
