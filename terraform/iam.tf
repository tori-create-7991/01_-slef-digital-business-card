resource "google_iam_workload_identity_pool" "github_pool" {
  provider                  = google-beta
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC provider for GitHub Actions"
  disabled                           = false

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service account for GitHub Actions CI/CD
# Direct WIF (principalSet) produces a federated token, but many Google APIs
# (including Firebase) require an OAuth 2 access token. Service account
# impersonation exchanges the federated token for a proper OAuth 2 token.
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-tf"
  display_name = "GitHub Actions Terraform"
  description  = "Service account impersonated by GitHub Actions via WIF"
  project      = var.project_id
}

locals {
  wif_member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
  sa_member  = "serviceAccount:${google_service_account.github_actions.email}"
  sa_roles = [
    "roles/firebase.admin",                # Firebase project & hosting
    "roles/serviceusage.serviceUsageAdmin", # Enable/disable APIs
    "roles/resourcemanager.projectIamAdmin", # Manage IAM bindings (for terraform)
    "roles/iam.workloadIdentityPoolAdmin",  # Manage WIF pools (for terraform)
    "roles/storage.admin",                  # Terraform state bucket
  ]
}

# Grant roles to the service account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(local.sa_roles)
  project  = var.project_id
  role     = each.value
  member   = local.sa_member
}

# Allow the WIF principal to impersonate the service account
resource "google_service_account_iam_member" "wif_impersonation" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.wif_member
}

output "wif_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The full name of the Workload Identity Provider"
}

output "service_account_email" {
  value       = google_service_account.github_actions.email
  description = "The email of the GitHub Actions service account"
}
