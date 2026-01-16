output "app_engine_application" {
  description = "The full App Engine application resource."
  value       = module.app_engine_example.app_engine_application
}

output "deployed_services" {
  description = "A map of the deployed App Engine service versions."
  value       = module.app_engine_example.services
}

output "domain_mappings" {
  description = "A map of the created custom domain mappings."
  value       = module.app_engine_example.domain_mappings
}

output "default_service_url" {
  description = "The default URL of the App Engine application."
  value       = "https://www.${var.domain_name}"
}

output "default_hostname" {
  description = "The default Google-provided hostname for the App Engine application."
  value       = module.app_engine_example.app_engine_application.default_hostname
}
