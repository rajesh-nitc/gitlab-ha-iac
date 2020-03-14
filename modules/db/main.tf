resource "google_compute_global_address" "private-ip-alloc" {
  provider = google-beta

  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = var.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private-ip-alloc.name}"]
}

resource "random_id" "db_name_suffix_primary" {
  byte_length = 4
}

resource "google_sql_database_instance" "primary" {
  provider = google-beta

  name   = "db-primary-${random_id.db_name_suffix_primary.hex}"
  database_version = var.database_version
  region = var.region_primary

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    availability_type = "REGIONAL"
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

resource "random_id" "db_name_suffix_dr" {
  byte_length = 4
}

resource "google_sql_database_instance" "dr" {
  provider = google-beta

  name                 = "db-dr-${random_id.db_name_suffix_dr.hex}"
  database_version = var.database_version
  master_instance_name = google_sql_database_instance.primary.name
  region               = var.region_dr

  depends_on = [google_service_networking_connection.private_vpc_connection]

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