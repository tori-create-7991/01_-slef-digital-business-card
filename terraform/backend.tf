terraform {
  backend "gcs" {
    # The bucket name will be passed via -backend-config="bucket=..." in the init command
    prefix  = "terraform/state"
  }
}
