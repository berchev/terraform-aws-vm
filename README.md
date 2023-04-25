# terraform-aws-vm

## Describtion ##
Ubuntu virtual machine configured with Terraform, Sentinel, Terraform Agent binary, Docker

## Instructions ##
- git clone https://github.com/berchev/terraform-aws-vm.git
- have a keypair created beforehand into a specific AWS region
- cd terraform-aws-vm
- edit main.tf according to your needs. More specifically:
  - variable `region`
  - variable `vm_key_name`
  - variable `private_key_path`
  - variable `tfca_version`
  - variable `tf_cli_version`
  - variable `sentinel_version`
- `export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXX`
- `export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
- `export AWS_SESSION_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
- terraform init
- terraform plan
- terraform apply
