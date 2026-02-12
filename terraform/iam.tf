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

# Grant predefined roles to GitHub Actions via WIF
# (Basic roles like roles/owner cannot be granted to principalSet://)
locals {
  wif_member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
  wif_roles = [
    "roles/firebase.admin",                   # Firebase project & hosting
    "roles/serviceusage.serviceUsageAdmin",    # Enable/disable APIs
    "roles/resourcemanager.projectIamAdmin",   # Manage IAM bindings (for terraform)
    "roles/iam.workloadIdentityPoolAdmin",     # Manage WIF pools (for terraform)
    "roles/storage.admin",                     # Terraform state bucket
  ]
}

resource "google_project_iam_member" "wif_roles" {
  for_each = toset(local.wif_roles)
  provider = google-beta
  project  = var.project_id
  role     = each.value
  member   = local.wif_member
}

output "wif_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The full name of the Workload Identity Provider"
}
