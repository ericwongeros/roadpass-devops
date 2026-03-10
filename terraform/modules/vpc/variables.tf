variable "availability_zones" {
  description = "List of availability zone names (e.g. us-east-1a, us-east-1b). Must have exactly 2 for the subnet layout."
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g. staging, production)."
  type        = string
}

variable "name" {
  description = "Name prefix for VPC and resources."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets. Order: AZ1 first two, then AZ2 first two (4 total)."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. Order: AZ1 first two, then AZ2 first two (4 total)."
  type        = list(string)
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 172.16.0.0/16)."
  type        = string
}
