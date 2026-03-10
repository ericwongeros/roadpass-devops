include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ec2-app"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id             = "vpc-mock"
    public_subnet_ids  = ["subnet-mock1", "subnet-mock2"]
    private_subnet_ids = ["subnet-mock3", "subnet-mock4"]
  }
}

inputs = {
  name                 = "roadpass"
  environment          = "staging"
  vpc_id               = dependency.vpc.outputs.vpc_id
  public_subnet_ids    = dependency.vpc.outputs.public_subnet_ids
  private_subnet_ids   = dependency.vpc.outputs.private_subnet_ids
  ami_id               = "ami-placeholder"
  instance_type        = "t3.micro"
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4
  app_name             = "roadpass-demo"
  message              = "Hello from userdata"
  ssh_allowed_cidrs    = ["10.0.0.0/8"]
  tags = {
    Project = "roadpass-devops-assignment"
  }
}
