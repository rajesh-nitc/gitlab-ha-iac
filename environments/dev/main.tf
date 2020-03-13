provider "google" {
  version     = "~> 2.1"
  credentials = file("../../../tf-sa.json")
  region      = var.region
  project     = var.project_id
}

provider "google-beta" {
  version     = "~> 2.1"
  credentials = file("../../../tf-sa.json")
  region      = var.region
  project     = var.project_id
}

module "vpc" {
  source         = "../../modules/vpc"
  project_id     = var.project_id
  region_primary = var.region_primary
  region_dr      = var.region_dr
  network_name   = var.network_name
}

module "instance_template_primary" {
  source                              = "../../modules/instance-template"
  instance_template_subnetwork        = "${element(module.vpc.subnets_names, 0)}"
  instance_template_name_prefix       = "gitlab-server-primary-"
  instance_template_machine_type      = var.instance_template_machine_type
  instance_template_region            = var.region_primary
  instance_template_disk_source_image = var.instance_template_disk_source_image
  instance_template_tags              = ["primary"]
}

module "instance_template_dr" {
  source                              = "../../modules/instance-template"
  instance_template_subnetwork        = "${element(module.vpc.subnets_names, 1)}"
  instance_template_name_prefix       = "gitlab-server-dr-"
  instance_template_machine_type      = var.instance_template_machine_type
  instance_template_region            = var.region_dr
  instance_template_disk_source_image = var.instance_template_disk_source_image
  instance_template_tags              = ["dr"]
}

module "health_check" {
  source = "../../modules/health-check"
}

module "mig_primary" {
  source                        = "../../modules/mig"
  mig_instance_template         = module.instance_template_primary.instance_template_self_link
  auto_healing_health_check     = module.health_check.health_check_self_link
  mig_name                      = "mig-primary"
  mig_base_instance_name        = "gitlab-primary"
  mig_region                    = var.region_primary
  mig_distribution_policy_zones = ["asia-south1-a", "asia-south1-b", "asia-south1-c"]
  mig_target_size               = 3
  named_port                    = var.named_port
}

module "mig_dr" {
  source                        = "../../modules/mig"
  mig_instance_template         = module.instance_template_dr.instance_template_self_link
  auto_healing_health_check     = module.health_check.health_check_self_link
  mig_name                      = "mig-dr"
  mig_base_instance_name        = "gitlab-dr"
  mig_region                    = var.region_dr
  mig_distribution_policy_zones = ["asia-southeast1-a"]
  mig_target_size               = 1
  named_port                    = var.named_port
}

module "glb" {
  source                     = "../../modules/glb"
  glb_ip_address             = var.glb_ip_address
  instance_group_primary_url = module.mig_primary.instance_group_url
  instance_group_dr_url      = module.mig_dr.instance_group_url
  health_check               = module.health_check.health_check_self_link
  named_port                 = var.named_port
  capacity_scaler_primary    = 1
  capacity_scaler_dr         = 0
}

module "db-primary" {
  source            = "../../modules/db-primary"
  network_self_link = module.vpc.network_self_link
  region_primary    = var.region_primary
  db_name           = var.db_name_primary
  db_user           = var.db_user
  db_password       = var.db_password
}

module "db-dr" {
  source               = "../../modules/db-dr"
  network_self_link    = module.vpc.network_self_link
  master_instance_name = module.db-primary.db_primary_name
  region_dr            = var.region_dr
}
