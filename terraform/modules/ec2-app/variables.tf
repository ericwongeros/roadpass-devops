variable "ami_id" {
  description = "AMI ID for the EC2 instances (e.g. from Packer-built nginx AMI)."
  type        = string
}

variable "app_name" {
  description = "Application name injected into instance user data (fry)."
  type        = string
  default     = "roadpass-demo"
}

variable "environment" {
  description = "Environment name (e.g. staging)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "message" {
  description = "Message injected into instance user data (fry)."
  type        = string
  default     = "Hello from userdata"
}

variable "name" {
  description = "Name prefix for resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ASG."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to instances (e.g. VPN/bastion). Instances are in private subnets; use SSM or bastion in practice."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum ASG size."
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum ASG size."
  type        = number
  default     = 2
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS listener."
  type        = string
  default     = null
}
