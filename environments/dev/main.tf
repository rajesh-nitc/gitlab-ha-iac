provider "google" {
  version = "~> 2.1"
  region  = "${var.region}"
  project = "${var.project_id}"
}

provider "google-beta" {
  version = "~> 2.1"
  region  = "${var.region}"
  project = "${var.project_id}"
}

module "glb" {
  source     = "../../../modules/glb"
  subnet = "${element(module.vpc.subnets_names, 1)}"
}

module "vpc" {
  source     = "../../../modules/vpc"
}