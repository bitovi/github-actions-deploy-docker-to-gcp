
# Create a VM instance from a public image
# in the `default` VPC network and subnet

resource "google_compute_instance" "tftest" {
  project = "278540881566"
  name         = "my-vm"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2210-kinetic-amd64-v20230126"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}