output "app_engine_application_id" {
  # description: The unique ID of the App Engine application.
  description = "The unique ID of the App Engine application."
  # value: The value of the output.
  value       = length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].id : "App Engine application creation was skipped."
}

output "app_engine_application_url" {
  # description: The default URL of the App Engine application.
  description = "The default URL of the App Engine application."
  # value: The value of the output.
  value       = length(google_app_engine_application.app) > 0 ? google_app_engine_application.app[0].default_hostname : "App Engine application creation was skipped."
}

output "service_name" {
  # description: The name of the deployed App Engine service.
  description = "The name of the deployed App Engine service."
  # value: The value of the output.
  value       = length(google_app_engine_standard_app_version.main) > 0 ? google_app_engine_standard_app_version.main[0].service : "App Engine version creation was skipped."
}

output "version_id" {
  # description: The ID of the deployed App Engine version.
  description = "The ID of the deployed App Engine version."
  # value: The value of the output.
  value       = length(google_app_engine_standard_app_version.main) > 0 ? google_app_engine_standard_app_version.main[0].version_id : "App Engine version creation was skipped."
}

output "version_name" {
  # description: The full resource name of the deployed App Engine version.
  description = "The full resource name of the deployed App Engine version."
  # value: The value of the output.
  value       = length(google_app_engine_standard_app_version.main) > 0 ? google_app_engine_standard_app_version.main[0].name : "App Engine version creation was skipped."
}
