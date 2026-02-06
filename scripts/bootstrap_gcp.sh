#!/bin/bash
set -e

# Configuration
REGION="us-central1"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"

echo "==================================================="
echo "   GCP Setup Script for Firebase + Terraform + WIF (Direct)"
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

# 4. Setup Workload Identity Federation
echo "Setting up Workload Identity Federation..."

# Create Pool
if ! gcloud iam workload-identity-pools describe "$POOL_NAME" --location="global" &>/dev/null; then
  gcloud iam workload-identity-pools create "$POOL_NAME" \
    --location="global" \
    --display-name="GitHub Actions Pool"
else
  echo "Pool $POOL_NAME already exists."
fi

# Get Pool ID
POOL_ID=$(gcloud iam workload-identity-pools describe "$POOL_NAME" --location="global" --format="value(name)")

# Create Provider
# If provider exists, delete it first to ensure clean state with correct OIDC config
if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" --location="global" --workload-identity-pool="$POOL_NAME" &>/dev/null; then
  echo "Provider $PROVIDER_NAME exists. Deleting to recreate..."
  gcloud iam workload-identity-pools providers delete "$PROVIDER_NAME" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --quiet
fi

echo "Creating Provider $PROVIDER_NAME..."
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
  --location="global" \
  --workload-identity-pool="$POOL_NAME" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# 5. Grant Permissions Directly to WIF Principal
# Granting Owner to the repository principal set
echo "Granting 'Owner' role directly to GitHub Repository Principal..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${GH_REPO}" \
  --role="roles/owner" --condition=None

PROVIDER_FULL_NAME=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" --location="global" --workload-identity-pool="$POOL_NAME" --format="value(name)")

echo ""
echo "==================================================="
echo "   SETUP COMPLETE!"
echo "==================================================="
echo "Please add the following Secrets to your GitHub Repository:"
echo ""
echo "GCP_PROJECT_ID      : $PROJECT_ID"
echo "GCP_TF_STATE_BUCKET : $BUCKET_NAME"
echo "WIF_PROVIDER        : $PROVIDER_FULL_NAME"
echo ""
echo "You can set these using GitHub CLI in Codespaces:"
echo "gh secret set GCP_PROJECT_ID -b \"$PROJECT_ID\""
echo "gh secret set GCP_TF_STATE_BUCKET -b \"$BUCKET_NAME\""
echo "gh secret set WIF_PROVIDER -b \"$PROVIDER_FULL_NAME\""
echo ""
