output "private_ips" {
  description = "application instance private ips"
  value       = data.aws_instances.application.private_ips
}

output "dns_name" {
  description = "alb dns"
  value       = aws_lb.alb1.dns_name
}