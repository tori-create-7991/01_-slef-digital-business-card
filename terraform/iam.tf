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

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Direct Workload Identity Federation: Grant roles directly to the PrincipalSet
resource "google_project_iam_member" "wif_owner" {
  provider = google-beta
  project  = var.project_id
  role     = "roles/owner"
  member   = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

output "wif_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "The full name of the Workload Identity Provider"
}
