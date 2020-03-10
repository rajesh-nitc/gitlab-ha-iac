resource "google_compute_instance_template" "gitlab-server-template" {
  name_prefix    = "gitlab-server-"
  machine_type   = "n1-standard-1"
  region         = "asia-south1"
  # tags           = ["foo","bar"]
  can_ip_forward = true

  metadata_startup_script = templatefile("${path.module}/templates/startup-script.tmpl", {})

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "${var.subnet}"

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

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  timeout_sec        = 5
  check_interval_sec = 5

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_instance_group_manager" "gitlab-server-mig-a" {
  name               = "gitlab-server-mig-a"
  base_instance_name = "gitlab-server"
  version {
    instance_template = "${google_compute_instance_template.gitlab-server-template.self_link}"
  }
  target_size = 1
  zone = "asia-south1-a"
  named_port {
    name = "http"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.self_link
    initial_delay_sec = 3600
  }
}

resource "google_compute_instance_group_manager" "gitlab-server-mig-b" {
  name               = "gitlab-server-mig-b"
  base_instance_name = "gitlab-server"
  version {
    instance_template = "${google_compute_instance_template.gitlab-server-template.self_link}"
  }
  zone = "asia-south1-c"
  target_size = 1

  named_port {
    name = "http"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.self_link
    initial_delay_sec = 100
  }
}

resource "google_compute_backend_service" "default" {
  name          = "gitlab-server-backend-service"
  port_name     = "http"
  health_checks = ["${google_compute_health_check.autohealing.self_link}"]

  backend {
    group = "${google_compute_instance_group_manager.gitlab-server-mig-a.instance_group}"
  }

  backend {
    group = "${google_compute_instance_group_manager.gitlab-server-mig-b.instance_group}"
  }

}

resource "google_compute_url_map" "default" {
  name            = "gitlab-server-url-map"
  default_service = "${google_compute_backend_service.default.self_link}"
}

resource "google_compute_target_https_proxy" "default" {
  name             = "gitlab-server-https-proxy"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [google_compute_ssl_certificate.default.self_link]
}

resource "google_compute_ssl_certificate" "default" {
  name        = "my-certificate"
  private_key = file("${path.module}/ssl-cert/live_budita.dev_privkey.pem")
  certificate = file("${path.module}/ssl-cert/live_budita.dev_cert.pem")
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  port_range = "443"
  ip_address = "34.107.133.237"
  target     = "${google_compute_target_https_proxy.default.self_link}"
}

resource "google_compute_autoscaler" "gitlab-server-mig-a-autoscaler" {
  name   = "gitlab-server-mig-a-autoscaler"
  zone   = "asia-south1-a"
  target = "${google_compute_instance_group_manager.gitlab-server-mig-a.self_link}"

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.8
    }
  }
}

resource "google_compute_autoscaler" "gitlab-server-mig-b-autoscaler" {
  name   = "gitlab-server-mig-b-autoscaler"
  zone   = "asia-south1-c"
  target = "${google_compute_instance_group_manager.gitlab-server-mig-b.self_link}"

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.8
    }
  }
}
