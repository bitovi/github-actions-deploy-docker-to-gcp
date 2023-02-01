# Create a VM instance from a public image
# in the `default` VPC network and subnet

resource "google_compute_instance" "gcp_instance" {
  project      = var.GCP_PROJECT_ID
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
    }
  }

  network_interface {
    network = var.network
    access_config {}
  }
}
