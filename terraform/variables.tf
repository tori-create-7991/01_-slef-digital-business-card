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
