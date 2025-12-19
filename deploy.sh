#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="wingspan-bird-quiz"
REGISTRY_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/wingspan-quiz"

echo -e "${GREEN}🦅 Wingspan Bird Quiz - Deployment Script${NC}"
echo "================================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 Using Project: ${PROJECT_ID}${NC}"
echo -e "${YELLOW}📍 Region: ${REGION}${NC}"

# Authenticate with Google Cloud
echo -e "\n${GREEN}Setting up authentication...${NC}"
gcloud auth application-default login

# Set the project
echo -e "\n${GREEN}Setting GCP project...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "\n${GREEN}Enabling required APIs...${NC}"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com

# Configure Docker authentication for Artifact Registry
echo -e "\n${GREEN}Configuring Docker authentication...${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Initialize Terraform (to create Artifact Registry)
echo -e "\n${GREEN}Initializing Terraform...${NC}"
cd terraform
terraform init

# Apply Terraform to create Artifact Registry ONLY (not Cloud Run yet)
echo -e "\n${GREEN}Creating Artifact Registry...${NC}"
terraform apply -target=google_project_service.artifact_registry \
                -target=google_project_service.container_registry \
                -target=google_artifact_registry_repository.wingspan_repo \
                -var="project_id=${PROJECT_ID}" \
                -var="region=${REGION}" \
                -auto-approve

# Get the registry URL
FULL_REGISTRY_URL=$(terraform output -raw artifact_registry_url 2>/dev/null || echo "${REGION}-docker.pkg.dev/${PROJECT_ID}/wingspan-quiz")

cd ..

# Build the Docker image
echo -e "\n${GREEN}Building Docker image...${NC}"
docker build -t ${SERVICE_NAME}:latest .

# Tag the image for Artifact Registry
echo -e "\n${GREEN}Tagging Docker image...${NC}"
docker tag ${SERVICE_NAME}:latest ${FULL_REGISTRY_URL}/${SERVICE_NAME}:latest

# Push the image to Artifact Registry
echo -e "\n${GREEN}Pushing Docker image to Artifact Registry...${NC}"
docker push ${FULL_REGISTRY_URL}/${SERVICE_NAME}:latest

# Now apply the full Terraform configuration (including Cloud Run)
echo -e "\n${GREEN}Deploying Cloud Run service...${NC}"
cd terraform
terraform apply -var="project_id=${PROJECT_ID}" -var="region=${REGION}" -auto-approve

cd ..

# Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --format 'value(status.url)')

echo -e "\n${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Service URL: ${SERVICE_URL}${NC}"
echo -e "\n${YELLOW}💡 Tip: The service will scale to zero when not in use (free tier friendly)${NC}"
