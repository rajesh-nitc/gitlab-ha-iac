output "db_instance_primary_name" {
  value = google_sql_database_instance.primary.name
}

output "db_instance_dr_name" {
  value = google_sql_database_instance.dr.name
}

