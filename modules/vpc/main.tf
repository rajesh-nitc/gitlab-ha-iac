module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.1"

  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "subnet-primary"
      subnet_ip             = "10.10.10.0/24"
      subnet_region         = var.region_primary
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "This subnet has a description"
    },
    {
      subnet_name           = "subnet-dr"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = var.region_dr
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "This subnet has a description"
    }
  ]

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]
}

resource "google_compute_firewall" "default" {
  name    = "gitlab-firewall"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
