provider "google" {
  version     = "~> 2.1"
  credentials = file("../../../tf-sa.json")
  project     = var.project_id
}

provider "google-beta" {
  version     = "~> 2.1"
  credentials = file("../../../tf-sa.json")
  project     = var.project_id
}

module "vpc" {
  source         = "../../modules/vpc"
  project_id     = var.project_id
  region_primary = "asia-south1"
  region_dr      = "asia-southeast1"
  network_name   = var.network_name
}

module "instance_template_primary" {
  source                              = "../../modules/instance-template"
  instance_template_subnetwork        = "${element(module.vpc.subnets_names, 0)}"
  instance_template_name_prefix       = "gitlab-server-primary-"
  instance_template_machine_type      = "n1-standard-1"
  region    = "asia-south1"
  instance_template_disk_source_image = "tf-first-project/gitlab-server"
  instance_template_tags              = ["primary"]
}

module "instance_template_dr" {
  source                              = "../../modules/instance-template"
  instance_template_subnetwork        = "${element(module.vpc.subnets_names, 1)}"
  instance_template_name_prefix       = "gitlab-server-dr-"
  instance_template_machine_type      = "n1-standard-1"
  region           = "asia-southeast1"
  instance_template_disk_source_image = "tf-first-project/gitlab-server"
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
  region    = "asia-south1"
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
  region           = "asia-southeast1"
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

module "db-primary-n-dr" {
  source            = "../../modules/db"
  network_self_link = module.vpc.network_self_link
  database_version  = "POSTGRES_9_6"
  region_primary = "asia-south1"
  region_dr      = "asia-southeast1"
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
}

# module "vm-test" {
#   source       = "../../modules/vm-test"
#   vm_subnetwork = "${element(module.vpc.subnets_names, 0)}"
#   project_id = var.project_id
#   region = "asia-south1"
#   db_instance_name = module.db-primary-n-dr.db_instance_primary_name
#   db_name           = var.db_name
#   db_user           = var.db_user
#   db_password       = var.db_password
# }
