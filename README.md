# Iac
Deploy highly available, resilient and scalable gitlab solution
## Getting Started

```
cd environments/dev
terraform init
terraform plan
terraform apply --auto-approve
```
This will deploy mig in primary region, mig in secondary or disaster recovery region, global load balancer, vpc, cloudsql and nfs
