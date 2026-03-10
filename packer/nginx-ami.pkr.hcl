packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "nginx" {
  ami_name      = "roadpass-nginx-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.aws_region
  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-kernel-6.1-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
  tags = {
    Name    = "roadpass-nginx-ami"
    Project = "roadpass-devops-assignment"
  }
}

build {
  sources = ["source.amazon-ebs.nginx"]
  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/playbook.yml"
    user          = "ec2-user"
    use_proxy     = false
    extra_arguments = [
      "--extra-vars", "ansible_ssh_common_args='-o HostKeyChecking=no'"
    ]
  }
}
