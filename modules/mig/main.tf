resource "google_compute_region_instance_group_manager" "mig" {
  name                      = var.mig_name
  base_instance_name        = var.mig_base_instance_name
  region                    = var.mig_region
  distribution_policy_zones = var.mig_distribution_policy_zones

  version {
    instance_template = var.mig_instance_template
  }

  target_size = var.mig_target_size
  named_port {
    name = var.named_port
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }

  auto_healing_policies {
    health_check      = var.auto_healing_health_check
    initial_delay_sec = 3600
  }
}
