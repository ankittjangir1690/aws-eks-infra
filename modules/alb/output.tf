output "alb_id" {
  description = "The ID of the Application Load Balancer"
  value       = aws_lb.myapp.id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.myapp_tg.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.myapp.dns_name
}
