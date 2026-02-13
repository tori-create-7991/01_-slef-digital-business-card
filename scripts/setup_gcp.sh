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

# 2b. Create Service Account for GitHub Actions
#     Direct WIF produces a federated token, but many Google APIs require an
#     OAuth 2 access token. A service account enables the impersonation flow
#     that produces a proper OAuth 2 token.
SA_NAME="github-actions-tf"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo "Creating service account for GitHub Actions..."
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
  echo "Service account $SA_EMAIL already exists."
else
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="GitHub Actions Terraform" \
    --description="Service account impersonated by GitHub Actions via WIF" \
    --project="$PROJECT_ID"
  echo "Created service account: $SA_EMAIL"
fi

echo "Granting IAM roles to service account..."
SA_ROLES=(
  "roles/firebase.admin"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/iam.workloadIdentityPoolAdmin"
  "roles/storage.admin"
)
for role in "${SA_ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role" \
    --quiet
done
echo "IAM roles granted."

# 3. Create Terraform State Bucket (cannot be managed by Terraform itself)
BUCKET_NAME="${PROJECT_ID}-tfstate"
if ! gcloud storage buckets describe "gs://$BUCKET_NAME" &>/dev/null; then
  echo "Creating GCS Bucket for Terraform State: $BUCKET_NAME"
  gcloud storage buckets create "gs://$BUCKET_NAME" --location="$REGION" --uniform-bucket-level-access
else
  echo "Bucket $BUCKET_NAME already exists."
  echo "Ensuring Uniform Bucket Level Access is enabled..."
  gcloud storage buckets update "gs://$BUCKET_NAME" --uniform-bucket-level-access
  # Enabling UBLA disables legacy ACLs, so the current user may lose access.
  # Grant explicit IAM role to ensure continued access to the state bucket.
  CURRENT_USER=$(gcloud config get-value account 2>/dev/null)
  if [ -n "$CURRENT_USER" ]; then
    echo "Granting storage.admin to $CURRENT_USER on state bucket..."
    gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
      --member="user:$CURRENT_USER" --role="roles/storage.admin" --quiet
  fi
fi

echo ""
echo "==================================================="
echo "   Terraform Init & Apply"
echo "==================================================="

cd terraform

# 4. Init Terraform with GCS backend
echo "Initializing Terraform..."
terraform init -migrate-state -backend-config="bucket=${BUCKET_NAME}"

# 5. Import pre-existing resources into state (idempotency for re-runs)
#    If resources exist in GCP but not in Terraform state (e.g., state was lost
#    or a previous run partially failed), terraform apply would fail with
#    409 "already exists" errors. We attempt to import each resource first;
#    failures are expected if the resource does not yet exist (first run).
echo "Importing any pre-existing resources into Terraform state..."

TF_VARS=(
  -var="project_id=${PROJECT_ID}"
  -var="github_repo=${GH_REPO}"
  -var="cloudflare_api_token=${CLOUDFLARE_API_TOKEN}"
  -var="cloudflare_zone_id=${CLOUDFLARE_ZONE_ID}"
)

import_if_missing() {
  local addr="$1" id="$2"
  if terraform state list 2>/dev/null | grep -qF "$addr"; then
    echo "  [skip] $addr (already in state)"
    return
  fi
  echo "  [import] Attempting: $addr"
  local import_output
  if import_output=$(terraform import "${TF_VARS[@]}" "$addr" "$id" 2>&1); then
    echo "  [imported] $addr"
  else
    # Show the actual error for debugging, then continue
    echo "  [skip] $addr — import failed (will try to create):"
    echo "$import_output" | tail -5 | sed 's/^/    /'
  fi
}

# WIF Pool & Provider
# GCP soft-deletes WIF pools for 30 days. During that period:
#   - create → 409 (already exists)
#   - import → fails (DELETED state)
# We must undelete first, then import.
echo "  Recovering any soft-deleted WIF resources..."
gcloud iam workload-identity-pools undelete github-pool \
  --location=global --project="$PROJECT_ID" 2>/dev/null \
  && echo "  [undeleted] WIF pool github-pool" || true
gcloud iam workload-identity-pools providers undelete github-provider \
  --workload-identity-pool=github-pool \
  --location=global --project="$PROJECT_ID" 2>/dev/null \
  && echo "  [undeleted] WIF provider github-provider" || true

import_if_missing \
  "google_iam_workload_identity_pool.github_pool" \
  "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/github-pool"

import_if_missing \
  "google_iam_workload_identity_pool_provider.github_provider" \
  "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/github-pool/providers/github-provider"

# Firebase
import_if_missing \
  "google_firebase_project.default" \
  "projects/${PROJECT_ID}"

import_if_missing \
  "google_firebase_hosting_site.card" \
  "projects/${PROJECT_ID}/sites/${PROJECT_ID}-card"

import_if_missing \
  "google_firebase_hosting_custom_domain.card" \
  "projects/${PROJECT_ID}/sites/${PROJECT_ID}-card/customDomains/card.tori-dev.com"

# Google Project Services
import_if_missing \
  "google_project_service.firebase" \
  "${PROJECT_ID}/firebase.googleapis.com"

import_if_missing \
  "google_project_service.serviceusage" \
  "${PROJECT_ID}/serviceusage.googleapis.com"

import_if_missing \
  "google_project_service.cloudresourcemanager" \
  "${PROJECT_ID}/cloudresourcemanager.googleapis.com"

# Service Account
import_if_missing \
  "google_service_account.github_actions" \
  "projects/${PROJECT_ID}/serviceAccounts/${SA_EMAIL}"

# Note: Cloudflare DNS records require record IDs (API lookup needed) for import.
# Skipped here because the Cloudflare provider handles duplicate A records gracefully.

echo "Import phase complete."
echo ""

# 6. Full terraform apply - creates ALL resources (WIF, Firebase, DNS, etc.)
#    Pre-existing resources were imported above to prevent 409 errors.
echo "Applying all Terraform resources..."
terraform apply -auto-approve \
  -var="project_id=${PROJECT_ID}" \
  -var="github_repo=${GH_REPO}" \
  -var="cloudflare_api_token=${CLOUDFLARE_API_TOKEN}" \
  -var="cloudflare_zone_id=${CLOUDFLARE_ZONE_ID}"

# Get the WIF Provider Name from Terraform output
PROVIDER_FULL_NAME=$(terraform output -raw wif_provider_name)

# Safety net: ensure WIF principal can impersonate the service account
# (Terraform should handle this, but gcloud is idempotent and ensures it)
WIF_POOL_NAME=$(gcloud iam workload-identity-pools describe github-pool \
  --location=global --project="$PROJECT_ID" --format="value(name)" 2>/dev/null || true)
if [ -n "$WIF_POOL_NAME" ]; then
  echo "Ensuring WIF impersonation binding on service account..."
  gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${WIF_POOL_NAME}/attribute.repository/${GH_REPO}" \
    --quiet
fi

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
echo "GCP_SA_EMAIL        : $SA_EMAIL"
echo "CLOUDFLARE_API_TOKEN: (Your Cloudflare API Token)"
echo "CLOUDFLARE_ZONE_ID  : (Your Cloudflare Zone ID)"
echo ""
