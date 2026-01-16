# This file contains the output definitions for the Terraform module.
output "app_engine_application" {
  description = "The full App Engine application resource object. This output is empty if `create_app` is false."
  value       = var.create_app ? one(google_app_engine_application.app[*]) : null
}

output "services" {
  description = "A map of the deployed App Engine service versions, keyed by their service name."
  value       = google_app_engine_standard_app_version.main
}

output "domain_mappings" {
  description = "A map of the created domain mappings, keyed by the domain name."
  value       = google_app_engine_domain_mapping.domains
}

output "app_engine_application_id" {
  description = "The globally unique identifier for the App Engine application."
  value       = var.create_app ? one(google_app_engine_application.app[*].id) : null
}
