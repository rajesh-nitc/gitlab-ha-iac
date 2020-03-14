resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "n1-standard-1"
  zone         = "asia-south1-a"

  tags = ["foo", "bar"]

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
    project_id = var.project_id,
    region = var.region
    db_instance_name = var.db_instance_name
    db_name=var.db_name
    db_user=var.db_user
    db_password=var.db_password
  })

  service_account {
    scopes = ["cloud-platform"]
  }
}
