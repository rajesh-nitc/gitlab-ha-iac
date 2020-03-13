resource "google_compute_global_address" "private_ip_address_dr" {
  provider = google-beta

  name          = "private-ip-address-dr"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = var.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip_address_dr.name}"]
}

resource "random_id" "db_name_suffix_dr" {
  byte_length = 4
}

resource "google_sql_database_instance" "dr" {
  provider = google-beta

  name                 = "dr-${random_id.db_name_suffix_dr.hex}"
  master_instance_name = var.master_instance_name
  region               = var.region_dr

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_self_link
    }
  }

  replica_configuration {
    connect_retry_interval = "30"
  }
}
