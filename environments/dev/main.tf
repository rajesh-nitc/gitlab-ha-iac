provider "google" {
  version     = "~> 2.1"
  credentials = file("../../../tf-sa.json")
  region      = "${var.region}"
  project     = "${var.project_id}"
}

provider "google-beta" {
  version     = "~> 2.1"
  credentials = file("../../../tf-sa.json")
  region      = "${var.region}"
  project     = "${var.project_id}"
}

module "vpc" {
  source         = "../../modules/vpc"
  project_id     = "${var.project_id}"
  region_primary = "${var.region_primary}"
  region_dr      = "${var.region_dr}"
}

module "instance_template_primary" {
  source                              = "../../modules/instance-template"
  instance_template_subnetwork        = "${element(module.vpc.subnets_names, 0)}"
  instance_template_name_prefix       = "${var.instance_template_primary_name_prefix}"
  instance_template_machine_type      = "${var.instance_template_primary_machine_type}"
  instance_template_region            = "${var.region_primary}"
  instance_template_disk_source_image = "${var.instance_template_primary_disk_source_image}"
}

module "instance_template_dr" {
  source                              = "../../modules/instance-template"
  instance_template_subnetwork        = "${element(module.vpc.subnets_names, 1)}"
  instance_template_name_prefix       = "${var.instance_template_dr_name_prefix}"
  instance_template_machine_type      = "${var.instance_template_dr_machine_type}"
  instance_template_region            = "${var.region_dr}"
  instance_template_disk_source_image = "${var.instance_template_dr_disk_source_image}"
}

module "health_check" {
  source = "../../modules/health-check"
}

module "mig_primary" {
  source                        = "../../modules/mig"
  mig_instance_template         = module.instance_template_primary.instance_template_self_link
  auto_healing_health_check     = module.health_check.health_check_self_link
  mig_name                      = "${var.mig_primary_name}"
  mig_base_instance_name        = "${var.mig_primary_base_instance_name}"
  mig_region                    = "${var.region_primary}"
  mig_distribution_policy_zones = "${var.mig_primary_distribution_policy_zones}"
  mig_target_size               = "${var.mig_primary_target_size}"
  named_port                    = "${var.named_port}"
}

module "mig_dr" {
  source                        = "../../modules/mig"
  mig_instance_template         = module.instance_template_dr.instance_template_self_link
  auto_healing_health_check     = module.health_check.health_check_self_link
  mig_name                      = "${var.mig_dr_name}"
  mig_base_instance_name        = "${var.mig_dr_base_instance_name}"
  mig_region                    = "${var.region_dr}"
  mig_distribution_policy_zones = "${var.mig_dr_distribution_policy_zones}"
  mig_target_size               = "${var.mig_dr_target_size}"
  named_port                    = "${var.named_port}"
}

module "glb" {
  source                     = "../../modules/glb"
  glb_ip_address             = "${var.glb_ip_address}"
  instance_group_primary_url = module.mig_primary.instance_group_url
  instance_group_dr_url      = module.mig_dr.instance_group_url
  health_check               = module.health_check.health_check_self_link
  named_port                 = "${var.named_port}"
}
