#!/bin/bash
set -e

# Configuration
REGION="us-central1"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"

echo "==================================================="
echo "   GCP Setup Script: Terraform State & WIF"
echo "==================================================="

# 1. Input Validation
if [ -z "$PROJECT_ID" ]; then
  read -p "Enter your Google Cloud Project ID: " PROJECT_ID
fi

if [ -z "$GH_REPO" ]; then
  read -p "Enter your GitHub Repository (username/repo): " GH_REPO
fi

# Clean up GH_REPO if it contains the full URL
GH_REPO=${GH_REPO#"https://github.com/"}
GH_REPO=${GH_REPO#"git@github.com:"}
GH_REPO=${GH_REPO%".git"}

echo "Setting up project: $PROJECT_ID"
echo "For GitHub Repo: $GH_REPO"

gcloud config set project "$PROJECT_ID"

# 2. Enable Required APIs for Setup
echo "Enabling IAM and Resource Manager APIs..."
gcloud services enable iam.googleapis.com cloudresourcemanager.googleapis.com serviceusage.googleapis.com

# 3. Create Terraform State Bucket
BUCKET_NAME="${PROJECT_ID}-tfstate"
if ! gcloud storage buckets describe "gs://$BUCKET_NAME" &>/dev/null; then
  echo "Creating GCS Bucket for Terraform State: $BUCKET_NAME"
  gcloud storage buckets create "gs://$BUCKET_NAME" --location="$REGION"
else
  echo "Bucket $BUCKET_NAME already exists."
fi

echo ""
echo "==================================================="
echo "   Terraform Initialization & WIF Setup"
echo "==================================================="

cd terraform

# Init Terraform
echo "Initializing Terraform..."
terraform init -migrate-state -backend-config="bucket=${BUCKET_NAME}"

# Import logic to handle re-runs safely
echo "Checking for existing WIF resources to import..."

# Construct full resource names for check and import
POOL_ID="projects/${PROJECT_ID}/locations/global/workloadIdentityPools/${POOL_NAME}"
PROVIDER_ID="${POOL_ID}/providers/${PROVIDER_NAME}"

# Check and Import Pool
if gcloud iam workload-identity-pools describe "$POOL_NAME" --location="global" >/dev/null 2>&1; then
    echo "Found existing Pool: $POOL_NAME"
    echo "Importing Pool into Terraform state..."
    terraform import \
      -var="project_id=${PROJECT_ID}" \
      -var="github_repo=${GH_REPO}" \
      -var="cloudflare_api_token=placeholder" \
      -var="cloudflare_zone_id=placeholder" \
      google_iam_workload_identity_pool.github_pool "$POOL_ID" || echo "Pool import skipped (likely already managed)"
else
    echo "Pool '$POOL_NAME' does not exist yet. It will be created by terraform apply."
fi

# Check and Import Provider
if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" --location="global" --workload-identity-pool="$POOL_NAME" >/dev/null 2>&1; then
    echo "Found existing Provider: $PROVIDER_NAME"
    echo "Importing Provider into Terraform state..."
    terraform import \
      -var="project_id=${PROJECT_ID}" \
      -var="github_repo=${GH_REPO}" \
      -var="cloudflare_api_token=placeholder" \
      -var="cloudflare_zone_id=placeholder" \
      google_iam_workload_identity_pool_provider.github_provider "$PROVIDER_ID" || echo "Provider import skipped (likely already managed)"
else
    echo "Provider '$PROVIDER_NAME' does not exist yet. It will be created by terraform apply."
fi

echo "Applying Terraform for WIF resources..."
# Only target the IAM/WIF resources. Use dummy values for Cloudflare as they are not targeted.
terraform apply -auto-approve \
  -target=google_iam_workload_identity_pool.github_pool \
  -target=google_iam_workload_identity_pool_provider.github_provider \
  -target=google_project_iam_member.wif_owner \
  -var="project_id=${PROJECT_ID}" \
  -var="github_repo=${GH_REPO}" \
  -var="cloudflare_api_token=placeholder" \
  -var="cloudflare_zone_id=placeholder"

# Get the Provider Name for output
# We can construct it reliably now that Terraform has run
PROVIDER_FULL_NAME="projects/${PROJECT_ID}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

cd ..

echo ""
echo "==================================================="
echo "   SETUP COMPLETE!"
echo "==================================================="
echo "Terraform state bucket and WIF resources are ready."
echo ""
echo "Please add the following Secrets to your GitHub Repository:"
echo ""
echo "GCP_PROJECT_ID      : $PROJECT_ID"
echo "GCP_TF_STATE_BUCKET : $BUCKET_NAME"
echo "WIF_PROVIDER        : $PROVIDER_FULL_NAME"
echo "CLOUDFLARE_API_TOKEN: (Your Cloudflare API Token)"
echo "CLOUDFLARE_ZONE_ID  : (Your Cloudflare Zone ID)"
echo ""
