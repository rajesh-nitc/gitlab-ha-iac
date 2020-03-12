region         = "asia-south1"
project_id     = "tf-first-project"
region_dr      = "asia-south1"
region_primary = "asia-southeast1"
network_name   = "gitlab-vpc"
glb_ip_address = ""
named_port     = "http"

instance_template_primary_name_prefix            = "gitlab-server-primary-"
instance_template_primary_machine_type           = "n1-standard-1"
instance_template_primary_disk_source_image      = "debian-cloud/debian-9"
instance_template_primary_tags                   = ["primary"]
instance_template_primary_can_ip_forward         = true
instance_template_primary_service_account_scopes = ["cloud-platform"]

instance_template_dr_name_prefix            = "gitlab-server-dr-"
instance_template_dr_machine_type           = "n1-standard-1"
instance_template_dr_disk_source_image      = "debian-cloud/debian-9"
instance_template_dr_tags                   = ["dr"]
instance_template_dr_can_ip_forward         = true
instance_template_dr_service_account_scopes = ["cloud-platform"]

mig_primary_name                      = "mig-primary"
mig_primary_base_instance_name        = "gitlab-primary"
mig_primary_distribution_policy_zones = ["asia-south1-a", "asia-south1-b", "asia-south1-c"]
mig_primary_target_size               = 2

mig_dr_name                      = "mig-dr"
mig_dr_base_instance_name        = "gitlab-dr"
mig_dr_distribution_policy_zones = ["asia-southeast1-a"]
mig_dr_target_size               = 1