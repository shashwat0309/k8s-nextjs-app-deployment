locals {
  cloudflare_ingress = [
    "203.0.113.0/24", # Example - replace with your other VPC IDs or other services 
  ]
}

resource "aws_ec2_managed_prefix_list" "cloudflare" {
  name           = "Cloudflare IPv4"
  address_family = "IPv4"
  max_entries    = 25

  tags = {
    Env = "live"
  }
}

resource "aws_ec2_managed_prefix_list_entry" "cloudflare_prefix_cidr" {
  for_each       = toset(local.cloudflare_ingress)
  cidr           = each.key
  description    = "Primary"
  prefix_list_id = aws_ec2_managed_prefix_list.cloudflare.id
}
