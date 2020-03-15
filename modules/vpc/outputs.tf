output "subnets_names" {
  value = module.vpc.subnets_names
}

output "network_self_link" {
  value = module.vpc.network_self_link
}

output "network_name" {
  value = module.vpc.network_name
}

output "subnets_ips" {
  value = module.vpc.subnets_ips
}
