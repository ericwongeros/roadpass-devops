output "private_route_table_ids" {
  description = "IDs of the private route tables (one per AZ)."
  value       = aws_route_table.private[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "public_route_table_ids" {
  description = "ID of the public route table."
  value       = [aws_route_table.public.id]
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID used by VPC interface endpoints (SSM)."
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}
