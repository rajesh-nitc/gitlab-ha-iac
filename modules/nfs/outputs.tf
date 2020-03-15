output "nfs_host" {
  value       = google_compute_instance.default.network_interface.0.network_ip
}