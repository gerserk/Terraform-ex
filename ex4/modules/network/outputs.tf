output "vpc_id" {
    description = "id of the vpc"
    value = aws_vpc.main.id
}
output "public_subnets_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public.*.id
}

output "private_subnets_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private.*.id
}