terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend will be configured during setup
  # Run setup.sh to configure this automatically
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "cloudrun" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_registry" {
  service            = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "wingspan_repo" {
  location      = var.region
  repository_id = "wingspan-quiz"
  description   = "Container images for Wingspan Bird Quiz"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry]
}

# Cloud Run service
resource "google_cloud_run_service" "wingspan_quiz" {
  name     = "wingspan-bird-quiz"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/wingspan-quiz/wingspan-quiz:latest"
        
        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }

        # Startup and liveness probes
        startup_probe {
          http_get {
            path = "/health"
            port = 8080
          }
          initial_delay_seconds = 10
          timeout_seconds       = 5
          period_seconds        = 10
          failure_threshold     = 3
        }

        liveness_probe {
          http_get {
            path = "/health"
            port = 8080
          }
          initial_delay_seconds = 30
          timeout_seconds       = 5
          period_seconds        = 30
          failure_threshold     = 3
        }
      }

      # Free tier friendly settings
      container_concurrency = 80
      timeout_seconds       = 300
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"  # Scale to zero for free tier
        "autoscaling.knative.dev/maxScale" = "2"  # Limit max instances
        "run.googleapis.com/cpu-throttling" = "true"
        "run.googleapis.com/startup-cpu-boost" = "false"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloudrun,
    google_artifact_registry_repository.wingspan_repo
  ]
}

# Make the service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.wingspan_quiz.name
  location = google_cloud_run_service.wingspan_quiz.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "artifact_registry_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/wingspan-quiz"
  description = "Artifact Registry URL for pushing container images"
}

# Output the service URL (will be empty until Cloud Run service is created)
output "service_url" {
  value       = try(google_cloud_run_service.wingspan_quiz.status[0].url, "Not yet deployed")
  description = "URL of the deployed Wingspan Bird Quiz application"
}
