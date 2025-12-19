# The ID of the App Engine application resource.
output "application_id" {
  description = "The ID of the App Engine application."
  value       = google_app_engine_application.app.id
}

# The name of the App Engine application, including the 'g~' prefix.
output "application_name" {
  description = "The name of the App Engine application."
  value       = google_app_engine_application.app.name
}

# A list of GCS bucket URLs that are used for the application.
output "application_code_bucket" {
  description = "The GCS bucket used for staging code for the application."
  value       = google_app_engine_application.app.code_bucket
}

# The default hostname for the App Engine application.
output "application_default_hostname" {
  description = "The default hostname for the App Engine application."
  value       = google_app_engine_application.app.default_hostname
}

# A map containing details of the created flexible App Engine services.
output "flexible_service_details" {
  description = "A map containing details of the created flexible App Engine services, keyed by service name."
  value = {
    for k, v in google_app_engine_flexible_app_version.flexible : k => {
      name       = v.name
      service    = v.service
      version_id = v.version_id
    }
  }
}

# A map containing details of the created standard App Engine services.
output "standard_service_details" {
  description = "A map containing details of the created standard App Engine services, keyed by service name."
  value = {
    for k, v in google_app_engine_standard_app_version.standard : k => {
      name       = v.name
      service    = v.service
      version_id = v.version_id
    }
  }
}
