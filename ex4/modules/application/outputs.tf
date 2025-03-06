output "private_ips" {
  description = "application instance private ips"
  value       = data.aws_instances.application.private_ips
}