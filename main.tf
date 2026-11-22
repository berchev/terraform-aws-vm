##### Variables ####

##### SSH key pair #####
# SSH key created beforehand on your computer

variable "key_name" {
  type    = string
  default = "aws-ssh-key-terraform"
}

variable "public_ssh_key_path" {
  type    = string
  default = "/Users/berchev/.ssh/aws-ssh-key-terraform.pub"
}

variable "private_ssh_key_path" {
  type    = string
  default = "/Users/berchev/.ssh/aws-ssh-key-terraform"
}

 
##### Desired AWS region and tools versions ####
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tfca_version" {
  type    = string
  default     = "1.34.0"
  description = "Terraform Cloud Agent version"
}

variable "tf_cli_version" {
  type    = string
  default     = "1.17.2"
  description = "Terraform CLI version"
}

variable "sentinel_version" {
  type    = string
  default     = "0.40.0"
  description = "Sentinel version"
}

########################################

variable "security_group_name" {
  type    = string
  default = "terraform_vm_sg"
}

variable "vm_type" {
  type    = string
  default = "t2.medium"
}


#### Code Begin ####
#### Provider definition code ####
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.63.0"
    }
  }
}

provider "aws" {
  region = var.region
}

########################################################################

resource "aws_key_pair" "terraform_vm" {
  key_name   = var.key_name
  public_key = file(var.public_ssh_key_path)
}

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
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "aws_terraform_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.vm_type
  key_name                    = aws_key_pair.terraform_vm.key_name
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
  value = "ssh -i ${var.private_ssh_key_path} ubuntu@${aws_instance.aws_terraform_vm.public_dns}"
}