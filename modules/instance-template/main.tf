resource "google_compute_instance_template" "appserver-template" {
  name_prefix    = var.instance_template_name_prefix
  machine_type   = var.instance_template_machine_type
  region         = var.region
  tags           = var.instance_template_tags
  can_ip_forward = true

  metadata_startup_script = templatefile("${path.module}/templates/startup-script.tmpl", {
    project_id       = var.project_id,
    region           = var.region,
    db_instance_name = var.db_instance_name,
    nfs_host         = var.nfs_host
  })

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = var.instance_template_disk_source_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.instance_template_subnetwork

    access_config {
    }
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
