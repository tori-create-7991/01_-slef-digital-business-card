variable "project_id" {
  description = "The ID of the Google Cloud Project"
  type        = string
}

variable "region" {
  description = "The region for resources"
  type        = string
  default     = "us-central1"
}

variable "site_id" {
  description = "The ID for the Firebase Hosting site (usually same as project ID or custom)"
  type        = string
  default     = "" # If empty, defaults to project-id
}

variable "github_repo" {
  description = "GitHub repository name (username/repo)"
  type        = string
}

# Cloudflare
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for tori-dev.com"
  type        = string
}

variable "custom_domain" {
  description = "Custom domain for Firebase Hosting"
  type        = string
  default     = "card.tori-dev.com"
}
