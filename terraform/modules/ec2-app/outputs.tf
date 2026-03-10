output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB for Route53 alias records."
  value       = aws_lb.main.zone_id
}

output "asg_name" {
  description = "Name of the autoscaling group."
  value       = aws_autoscaling_group.main.name
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.main.arn
}
