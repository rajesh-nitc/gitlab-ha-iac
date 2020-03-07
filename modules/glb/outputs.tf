output "lb_global_address" {
  value = "${google_compute_global_forwarding_rule.fe.ip_address}"
}

