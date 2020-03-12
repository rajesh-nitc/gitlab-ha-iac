output "instance_template_self_link" {
  value = "${google_compute_instance_template.appserver-template.self_link}"
}
