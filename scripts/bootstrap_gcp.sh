#!/bin/bash
set -e

# Configuration
REGION="us-central1"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
SA_NAME="tf-action-sa"

echo "==================================================="
echo "   GCP Setup Script for Firebase + Terraform + WIF"
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

# 4. Create Service Account
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  echo "Creating Service Account: $SA_NAME"
  gcloud iam service-accounts create "$SA_NAME" --display-name="Terraform GitHub Actions"
  echo "Waiting 15 seconds for Service Account propagation..."
  sleep 15
else
  echo "Service Account $SA_NAME already exists."
fi

# 5. Grant Permissions to Service Account
# Granting Owner to ensure Terraform can do everything (APIs, Firebase, etc.)
echo "Granting 'Owner' role to Service Account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/owner" --condition=None

# 6. Setup Workload Identity Federation
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
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" --location="global" --workload-identity-pool="$POOL_NAME" &>/dev/null; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
    --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --display-name="GitHub Actions Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --issuer-uri="https://token.actions.githubusercontent.com"
else
  echo "Provider $PROVIDER_NAME already exists."
fi

# Allow GitHub Repo to impersonate Service Account
echo "Binding GitHub Repo to Service Account..."
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${GH_REPO}"

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
echo "WIF_SERVICE_ACCOUNT : $SA_EMAIL"
echo ""
echo "You can set these using GitHub CLI in Codespaces:"
echo "gh secret set GCP_PROJECT_ID -b \"$PROJECT_ID\""
echo "gh secret set GCP_TF_STATE_BUCKET -b \"$BUCKET_NAME\""
echo "gh secret set WIF_PROVIDER -b \"$PROVIDER_FULL_NAME\""
echo "gh secret set WIF_SERVICE_ACCOUNT -b \"$SA_EMAIL\""
echo ""
