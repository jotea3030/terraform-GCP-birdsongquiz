#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🦅 Wingspan Bird Quiz - Simple Setup${NC}"
echo "================================================"

# Prompt for project ID if not set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "\n${YELLOW}Enter your GCP Project ID:${NC}"
    read -p "Project ID: " GCP_PROJECT_ID
    export GCP_PROJECT_ID
fi

# Prompt for region
if [ -z "$GCP_REGION" ]; then
    echo -e "\n${YELLOW}Enter your preferred region (default: us-central1):${NC}"
    read -p "Region [us-central1]: " input_region
    GCP_REGION=${input_region:-us-central1}
    export GCP_REGION
fi

echo -e "\n${BLUE}📋 Configuration:${NC}"
echo -e "   Project ID: ${GCP_PROJECT_ID}"
echo -e "   Region: ${GCP_REGION}"

# Step 1: Authenticate
echo -e "\n${GREEN}Step 1: Authenticating with Google Cloud...${NC}"
echo -e "${YELLOW}This will open TWO browser windows. Please authenticate in both.${NC}"
read -p "Press Enter to continue..."

echo -e "\n${YELLOW}Opening first authentication (user login)...${NC}"
gcloud auth login

echo -e "\n${YELLOW}Opening second authentication (application credentials)...${NC}"
gcloud auth application-default login

echo -e "${GREEN}✅ Authentication complete${NC}"

# Step 2: Set project
echo -e "\n${GREEN}Step 2: Setting active project...${NC}"
gcloud config set project ${GCP_PROJECT_ID}
echo -e "${GREEN}✅ Project set${NC}"

# Step 3: Remind about billing
echo -e "\n${BLUE}Step 3: Billing Reminder${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT: Ensure billing is enabled for your project${NC}"
echo -e "${YELLOW}Visit: https://console.cloud.google.com/billing/linkedaccount?project=${GCP_PROJECT_ID}${NC}"
echo -e "${YELLOW}Even for free tier, billing must be enabled.${NC}"
read -p "Press Enter after confirming billing is enabled..."

# Step 4: Enable required APIs
echo -e "\n${GREEN}Step 4: Enabling required APIs (this may take 2-3 minutes)...${NC}"
gcloud services enable run.googleapis.com
echo -e "${GREEN}  ✅ Cloud Run API enabled${NC}"

gcloud services enable artifactregistry.googleapis.com
echo -e "${GREEN}  ✅ Artifact Registry API enabled${NC}"

gcloud services enable cloudbuild.googleapis.com
echo -e "${GREEN}  ✅ Cloud Build API enabled${NC}"

gcloud services enable cloudresourcemanager.googleapis.com
echo -e "${GREEN}  ✅ Resource Manager API enabled${NC}"

echo -e "${GREEN}✅ All APIs enabled${NC}"

# Step 5: Create Terraform state bucket
BUCKET_NAME="wingspan-quiz-tf-${GCP_PROJECT_ID}"
echo -e "\n${GREEN}Step 5: Creating Terraform state bucket...${NC}"
echo -e "${YELLOW}Bucket name: ${BUCKET_NAME}${NC}"

if gsutil ls -b gs://${BUCKET_NAME} &>/dev/null; then
    echo -e "${YELLOW}Bucket already exists${NC}"
else
    gsutil mb -p ${GCP_PROJECT_ID} -l ${GCP_REGION} gs://${BUCKET_NAME}
    gsutil versioning set on gs://${BUCKET_NAME}
    echo -e "${GREEN}✅ Created bucket: ${BUCKET_NAME}${NC}"
fi

# Step 6: Create Terraform backend config
echo -e "\n${GREEN}Step 6: Configuring Terraform...${NC}"

if [ ! -d "terraform" ]; then
    mkdir -p terraform
fi

cat > terraform/backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${BUCKET_NAME}"
    prefix = "terraform/state"
  }
}
EOF

echo -e "${GREEN}✅ Created terraform/backend.tf${NC}"

# Step 7: Create terraform.tfvars
cat > terraform/terraform.tfvars <<EOF
project_id  = "${GCP_PROJECT_ID}"
region      = "${GCP_REGION}"
environment = "production"
EOF

echo -e "${GREEN}✅ Created terraform/terraform.tfvars${NC}"

# Step 8: Save environment variables
cat > .env.deploy <<EOF
export GCP_PROJECT_ID="${GCP_PROJECT_ID}"
export GCP_REGION="${GCP_REGION}"
EOF

echo -e "${GREEN}✅ Saved environment variables to .env.deploy${NC}"

# Summary
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "1. ${YELLOW}source .env.deploy${NC}"
echo -e "2. ${YELLOW}./deploy.sh${NC}"
echo -e "\n${YELLOW}💡 If you close your terminal, run 'source .env.deploy' before deploying.${NC}"
