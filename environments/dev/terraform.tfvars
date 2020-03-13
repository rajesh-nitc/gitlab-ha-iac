region         = "asia-south1"
project_id     = "tf-first-project"
region_dr      = "asia-south1"
region_primary = "asia-southeast1"
network_name   = "gitlab-vpc"
glb_ip_address = ""
named_port     = "http"

instance_template_machine_type      = "n1-standard-1"
instance_template_disk_source_image = "tf-first-project/gitlab-server"

db_name_primary = "gitlabhq_production"
db_user         = "gitlab"
db_password     = "gitlab"
