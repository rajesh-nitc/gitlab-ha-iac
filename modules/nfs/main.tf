resource "google_compute_instance" "default" {
  name         = "nfs"
  machine_type = "n1-standard-1"
  zone         = "asia-south1-a"

  tags = ["nfs"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    subnetwork = var.vm_subnetwork

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = templatefile("${path.module}/templates/startup-script.tmpl", {
    primary_clients_subnet_ip = var.primary_clients_subnet_ip,
    dr_clients_subnet_ip = var.dr_clients_subnet_ip
  })

  service_account {
    scopes = ["cloud-platform"]
  }
}
