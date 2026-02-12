#!/bin/bash
set -e

# Configuration
REGION="us-central1"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"

echo "==================================================="
echo "   GCP Initial Setup Script"
echo "==================================================="
echo ""
echo "This script bootstraps the GCP project for CI/CD."
echo "It creates the Terraform state bucket, then runs"
echo "a full 'terraform apply' to provision all resources"
echo "(WIF, Firebase, Cloudflare DNS, etc.)."
echo ""
echo "After this, GitHub Actions will manage everything"
echo "via terraform apply on each push to main."
echo ""

# 1. Input Validation
if [ -z "$PROJECT_ID" ]; then
  read -p "Enter your Google Cloud Project ID: " PROJECT_ID
fi

if [ -z "$GH_REPO" ]; then
  read -p "Enter your GitHub Repository (username/repo): " GH_REPO
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  read -p "Enter your Cloudflare API Token: " CLOUDFLARE_API_TOKEN
fi

if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
  read -p "Enter your Cloudflare Zone ID: " CLOUDFLARE_ZONE_ID
fi

# Clean up GH_REPO if it contains the full URL
GH_REPO=${GH_REPO#"https://github.com/"}
GH_REPO=${GH_REPO#"git@github.com:"}
GH_REPO=${GH_REPO%".git"}

echo "Setting up project: $PROJECT_ID"
echo "For GitHub Repo: $GH_REPO"

gcloud config set project "$PROJECT_ID"

# 2. Enable minimum APIs required for Terraform to work
echo "Enabling required APIs..."
gcloud services enable iam.googleapis.com cloudresourcemanager.googleapis.com serviceusage.googleapis.com

# 3. Create Terraform State Bucket (cannot be managed by Terraform itself)
BUCKET_NAME="${PROJECT_ID}-tfstate"
if ! gcloud storage buckets describe "gs://$BUCKET_NAME" &>/dev/null; then
  echo "Creating GCS Bucket for Terraform State: $BUCKET_NAME"
  gcloud storage buckets create "gs://$BUCKET_NAME" --location="$REGION"
else
  echo "Bucket $BUCKET_NAME already exists."
fi

echo ""
echo "==================================================="
echo "   Terraform Init & Apply"
echo "==================================================="

cd terraform

# 4. Init Terraform with GCS backend
echo "Initializing Terraform..."
terraform init -migrate-state -backend-config="bucket=${BUCKET_NAME}"

# 5. Full terraform apply - creates ALL resources (WIF, Firebase, DNS, etc.)
#    This is idempotent: safe to run even if resources already exist.
echo "Applying all Terraform resources..."
terraform apply -auto-approve \
  -var="project_id=${PROJECT_ID}" \
  -var="github_repo=${GH_REPO}" \
  -var="cloudflare_api_token=${CLOUDFLARE_API_TOKEN}" \
  -var="cloudflare_zone_id=${CLOUDFLARE_ZONE_ID}"

# Get the WIF Provider Name from Terraform output
PROVIDER_FULL_NAME=$(terraform output -raw wif_provider_name)

cd ..

echo ""
echo "==================================================="
echo "   SETUP COMPLETE!"
echo "==================================================="
echo "All infrastructure has been provisioned."
echo ""
echo "Please add the following Secrets to your GitHub Repository:"
echo ""
echo "GCP_PROJECT_ID      : $PROJECT_ID"
echo "GCP_TF_STATE_BUCKET : $BUCKET_NAME"
echo "WIF_PROVIDER        : $PROVIDER_FULL_NAME"
echo "CLOUDFLARE_API_TOKEN: (Your Cloudflare API Token)"
echo "CLOUDFLARE_ZONE_ID  : (Your Cloudflare Zone ID)"
echo ""
