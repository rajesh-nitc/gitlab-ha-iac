resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  timeout_sec        = 5
  check_interval_sec = 5

  tcp_health_check {
    port = "80"
  }
}