resource "google_compute_backend_service" "default" {
  name          = "gitlab-server-backend-service"
  port_name     = ["${var.named_port}"]
  health_checks = ["${var.health_check}"]

  backend {
    group = "${var.instance_group_primary_url}"
  }

  backend {
    group = "${var.instance_group_dr_url}"
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
  ip_address = "${var.glb_ip_address}"
  target     = "${google_compute_target_https_proxy.default.self_link}"
}
