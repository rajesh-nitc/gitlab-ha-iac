output "health_check_self_link" {
  value = "${google_compute_health_check.autohealing.self_link}"
}
