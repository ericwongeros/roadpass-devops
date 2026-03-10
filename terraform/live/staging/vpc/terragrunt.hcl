include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  name        = "roadpass"
  environment = "staging"
  vpc_cidr    = "172.16.0.0/16"
  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]
  public_subnet_cidrs = [
    "172.16.0.0/20",
    "172.16.16.0/20",
    "172.16.32.0/20",
    "172.16.48.0/20"
  ]
  private_subnet_cidrs = [
    "172.16.64.0/20",
    "172.16.80.0/20",
    "172.16.96.0/20",
    "172.16.112.0/20"
  ]
  tags = {
    Project = "roadpass-devops-assignment"
  }
}
