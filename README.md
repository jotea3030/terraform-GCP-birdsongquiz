# Wingspan Bird Quiz - Google Cloud Deployment

A React-based bird identification quiz game featuring all 436 birds from Wingspan and its expansions, deployed on Google Cloud Platform's free tier.

## 🏗️ Architecture

- **Frontend**: React app with Tailwind CSS
- **Hosting**: Google Cloud Run (scales to zero, free tier eligible)
- **Container Registry**: Google Artifact Registry
- **Infrastructure**: Terraform for Infrastructure as Code
- **CI/CD**: Automated deployment script

## 📋 Prerequisites

1. **Google Cloud Platform Account**
   - Create a free account at https://cloud.google.com/free
   - Free tier includes: 2 million Cloud Run requests/month

2. **Required Tools**
   ```bash
   # Install gcloud CLI
   # https://cloud.google.com/sdk/docs/install
   
   # Install Terraform
   # https://developer.hashicorp.com/terraform/downloads
   
   # Install Docker
   # https://docs.docker.com/get-docker/
   
   # Install Node.js (for local development)
   # https://nodejs.org/
   ```

3. **GCP Project Setup**
   ```bash
   # Create a new GCP project
   gcloud projects create wingspan-quiz-[UNIQUE-ID]
   
   # Set billing account (required even for free tier)
   gcloud billing projects link wingspan-quiz-[UNIQUE-ID] \
     --billing-account=[YOUR-BILLING-ACCOUNT-ID]
   ```

## 🚀 Quick Start Deployment

### 1. Clone and Setup

```bash
# Create project directory
mkdir wingspan-bird-quiz
cd wingspan-bird-quiz

# Create directory structure
mkdir -p src terraform public

# Copy all the files from the artifacts into their respective locations
```

### 2. Initial Setup (One-time)

```bash
# Make scripts executable
chmod +x setup.sh deploy.sh

# Run the setup script - this will:
# - Authenticate with Google Cloud
# - Set up your project
# - Enable required APIs
# - Create the Terraform state bucket
# - Configure Terraform
./setup.sh

# Source the environment variables
source .env.deploy
```

The setup script will prompt you for:
- **GCP Project ID**: Your Google Cloud project ID
- **Region**: The GCP region (default: us-central1)

### 3. Deploy the Application

```bash
# Deploy everything
./deploy.sh
```

```
wingspan-bird-quiz/
├── src/
│   └── App.js                 # React component
├── public/
│   └── index.html            # HTML template
├── terraform/
│   ├── main.tf               # Terraform configuration
│   ├── variables.tf          # Variable definitions
│   └── terraform.tfvars      # Your configuration values
├── Dockerfile                # Container definition
├── nginx.conf               # Nginx configuration
├── package.json             # Node dependencies
├── deploy.sh                # Deployment script
└── README.md                # This file
```

### 5. Create Required Files

**public/index.html**:
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="Wingspan Bird Quiz - Test your bird call knowledge" />
    <title>Wingspan Bird Quiz</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
```

**src/index.js**:
```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

### 6. (Optional) Customize Configuration

If you want to manually configure instead of using setup.sh:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project details
nano terraform.tfvars
```

Update with your values:
```hcl
project_id  = "wingspan-quiz-123456"
region      = "us-central1"
environment = "production"
```

### 5. Create Terraform State Bucket

```bash
# Create bucket for Terraform state (required before deployment)
export PROJECT_ID="your-project-id"
gsutil mb -p ${PROJECT_ID} gs://wingspan-quiz-terraform-state
gsutil versioning set on gs://wingspan-quiz-terraform-state
```

### 6. Deploy

```bash
# Make deployment script executable
chmod +x deploy.sh

# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"

# Run deployment
./deploy.sh
```

## 🎮 Local Development

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

## 💰 Cost Optimization (Free Tier)

The configuration is optimized for GCP's free tier:

- **Cloud Run**: 2 million requests/month free
- **Scale to Zero**: No charges when idle
- **CPU Throttling**: Enabled to reduce costs
- **Memory**: 512Mi (within free tier limits)
- **Max Instances**: Limited to 2
- **Artifact Registry**: 0.5GB storage free

### Monthly Cost Estimate
- **0-2M requests**: $0 (free tier)
- **Idle time**: $0 (scales to zero)
- **Expected**: $0/month for typical usage

## 🔧 Customization

### Update API Key
Edit `src/App.js` and update:
```javascript
const XENO_CANTO_API_KEY = "your-api-key-here";
```

### Change Bird List
Modify the `WingspanBirds` array in `src/App.js` to customize available birds.

### Adjust Resources
Edit `terraform/main.tf` to modify:
- Memory limits
- CPU allocation
- Scaling parameters
- Timeout values

## 📊 Monitoring

```bash
# View logs
gcloud run services logs read wingspan-bird-quiz --region us-central1

# View metrics
gcloud run services describe wingspan-bird-quiz --region us-central1

# Monitor costs
gcloud billing accounts list
gcloud billing projects describe wingspan-quiz-123456
```

## 🔄 Update Deployment

```bash
# Make changes to your code
# Then redeploy:
./deploy.sh
```

## 🧹 Cleanup

```bash
# Destroy all resources
cd terraform
terraform destroy -var="project_id=${PROJECT_ID}" -var="region=${REGION}"

# Delete state bucket
gsutil rm -r gs://wingspan-quiz-terraform-state

# Delete project (optional)
gcloud projects delete wingspan-quiz-123456
```

## 🐛 Troubleshooting

### Issue: "Permission denied" errors
```bash
# Ensure you're authenticated
gcloud auth login
gcloud auth application-default login
```

### Issue: API not enabled
```bash
# Manually enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Issue: Docker authentication fails
```bash
# Reconfigure Docker
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Issue: Terraform state locked
```bash
# Force unlock (use with caution)
cd terraform
terraform force-unlock [LOCK_ID]
```

## 📝 License

This project uses the Xeno-canto API for bird recordings. Please ensure compliance with their terms of service.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📚 Resources

- [Google Cloud Free Tier](https://cloud.google.com/free)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Xeno-canto API](https://xeno-canto.org/explore/api)
- [Wingspan Board Game](https://stonemaiergames.com/games/wingspan/)

## 🎯 Features

- ✅ All 436 birds from Wingspan expansions
- ✅ Real bird call recordings from Xeno-canto
- ✅ Multiple choice quiz format
- ✅ Audio replay functionality
- ✅ Score tracking
- ✅ Responsive design
- ✅ Free tier hosting
- ✅ Auto-scaling
- ✅ Infrastructure as Code
