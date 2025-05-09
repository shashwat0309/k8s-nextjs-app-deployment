output "vpc_id" {
  description = "The VPC id"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "The private subnets of the VPC"
  value       = module.vpc.private_subnets
}
