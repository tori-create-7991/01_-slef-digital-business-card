# Cloudflare DNS records for Firebase Hosting
resource "cloudflare_record" "card_a1" {
  zone_id = var.cloudflare_zone_id
  name    = "card"
  content = "199.36.158.100"
  type    = "A"
  ttl     = 1
  proxied = false
}

resource "cloudflare_record" "card_a2" {
  zone_id = var.cloudflare_zone_id
  name    = "card"
  content = "199.36.159.100"
  type    = "A"
  ttl     = 1
  proxied = false
}
