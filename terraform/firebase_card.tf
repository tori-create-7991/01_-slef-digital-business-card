# card.tori-dev.com 用の新しいHostingサイト
resource "google_firebase_hosting_site" "card" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-card"

  depends_on = [google_firebase_project.default]
}

# カスタムドメイン設定
resource "google_firebase_hosting_custom_domain" "card" {
  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.card.site_id
  custom_domain = "card.tori-dev.com"

  wait_dns_verification = false
}

output "card_site_id" {
  value       = google_firebase_hosting_site.card.site_id
  description = "Site ID for card subdomain"
}

output "card_domain_url" {
  value       = "https://card.tori-dev.com"
  description = "Card subdomain URL"
}
