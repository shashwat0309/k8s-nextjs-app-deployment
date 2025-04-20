module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.cidr
  azs  = local.azs

  private_subnets = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 48)]

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_dns_hostnames = true

  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false

  manage_default_network_acl    = true
  default_network_acl_tags      = { name = "${local.cluster_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { name = "${local.cluster_name}-default" }
  manage_default_security_group = true
  default_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  // The tags for subnets are quite crucial as those are used by AWS to automatically
  // provision public and internal load balancers in the appropriate subnets.

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    "karpenter.sh/discovery"                      = local.cluster_name # Karpenter auto-discovery
  }
}
