terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  user_project_override = true
}

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

# Create/Manage the Firebase Hosting Site
# Note: The default site (project-id.web.app) is automatically created with the project
# but we can reference it or create a new channel/site if needed.
# For the main site, we usually just ensure the API is on.
# But `google_firebase_hosting_site` resource exists to create *additional* sites.
# To manage the *default* site, we just need the project to be a firebase project.
# We will just output the site URL.

# However, we can use `google_firebase_web_app` if we needed a web app config,
# but for Hosting-only, just being a Firebase project is enough.

output "hosting_site_url" {
  value = "https://${var.project_id}.web.app"
  description = "The default Firebase Hosting URL"
}
