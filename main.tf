##### Variables ####
##### Change values if necessary #### 
variable "region" {
  default = "us-east-1"
}

variable "security_group_name" {
  default = "terraform_vm_sg"
}

variable "vm_type" {
  default = "t2.small" #"t2.medium"
}

variable "vm_key_name" {
  default = "georgiberchev"
}


variable "private_key_path" {
  default = "/Users/georgiman/Dropbox/ec2_key_pair/georgiberchev.pem"
}

variable "tfca_version" {
  default     = "1.8.0"
  description = "Terraform Cloud Agent version"
}

variable "tf_cli_version" {
  default     = "1.4.5"
  description = "Terraform CLI version"
}

variable "sentinel_version" {
  default     = "0.21.0"
  description = "Sentinel version"
}

#### Code Begin ####
#### Provider definition code ####
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.64.0"
    }
  }
}

provider "aws" {
  region = var.region
}

########################################################################
#### Security group code ####
resource "aws_security_group" "terraform_vm_sg" {
  name        = var.security_group_name
  description = "Security group of the terraform VM"
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.terraform_vm_sg.id
}

resource "aws_security_group_rule" "allow_ingress" {
  type        = "ingress"
  to_port     = 0
  protocol    = "-1"
  from_port   = 0
  cidr_blocks = ["0.0.0.0/0"]
  #ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.terraform_vm_sg.id
}
########################################################################
#### AWS Virtual Machine code ####
data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "aws_terraform_vm" {
  ami                         = data.aws_ami.ubuntu_focal.id
  instance_type               = var.vm_type
  key_name                    = var.vm_key_name
  vpc_security_group_ids      = [aws_security_group.terraform_vm_sg.id]
  associate_public_ip_address = true
  user_data_base64 = base64encode(templatefile("${path.root}/config/cloud-init.tmpl", {
    tfc_agent_download_content = base64encode(templatefile("${path.root}/config/tfc-agent-download.sh.tmpl", {
      tfca_ver = var.tfca_version
    })),
    terraform_download_content = base64encode(templatefile("${path.root}/config/terraform-download.sh.tmpl", {
      tf_cli_ver = var.tf_cli_version
    })),
    sentinel_download_content = base64encode(templatefile("${path.root}/config/sentinel-download.sh.tmpl", {
      sentinel_ver = var.sentinel_version
    })),
    docker_download_content = base64encode(file("${path.root}/config/docker-download.sh.tmpl"))
  }))
}

#### Userdata templatefile(path, vars) ####
#### Code for only transferring the files in the VM ####
#   user_data_base64 = base64encode(templatefile("${path.root}/config/cloud-init.tmpl", {
#     tfc_agent_download_content = base64encode(file("${path.root}/config/tfc-agent-download.sh.tmpl")),
#     terraform_download_content = base64encode(file("${path.root}/config/terraform-download.sh.tmpl")),
#     sentinel_download_content = base64encode(file("${path.root}/config/sentinel-download.sh.tmpl")),
#     docker_download_content = base64encode(file("${path.root}/config/docker-download.sh.tmpl"))
#   }))
########################################################################
#### Terraform outputs ####

output "public_dns" {
  value = aws_instance.aws_terraform_vm.public_dns
}

output "ssh" {
  value = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.aws_terraform_vm.public_dns}"
}