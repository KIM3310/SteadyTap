provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_v2_service" "steadytap_backend" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = var.image

      ports {
        container_port = 8000
      }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  location = google_cloud_run_v2_service.steadytap_backend.location
  service  = google_cloud_run_v2_service.steadytap_backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
