resource "google_compute_global_address" "private_ip_address_primary" {
  provider = google-beta

  name          = "private-ip-address-primary"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = var.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip_address_primary.name}"]
}

resource "random_id" "db_name_suffix_primary" {
  byte_length = 4
}

resource "google_sql_database_instance" "primary" {
  provider = google-beta

  name   = "primary-${random_id.db_name_suffix_primary.hex}"
  region = var.region_primary

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
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.primary.name
  password = var.db_password
}
