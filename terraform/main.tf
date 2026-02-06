# Enable required APIs
resource "google_project_service" "firebase" {
  provider = google-beta
  project  = var.project_id
  service  = "firebase.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "serviceusage" {
  provider = google-beta
  project  = var.project_id
  service  = "serviceusage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  provider = google-beta
  project  = var.project_id
  service  = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Initialize Firebase for the project
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id

  depends_on = [
    google_project_service.firebase,
    google_project_service.serviceusage,
    google_project_service.cloudresourcemanager,
  ]
}

output "hosting_site_url" {
  value = "https://${var.project_id}.web.app"
  description = "The default Firebase Hosting URL"
}
