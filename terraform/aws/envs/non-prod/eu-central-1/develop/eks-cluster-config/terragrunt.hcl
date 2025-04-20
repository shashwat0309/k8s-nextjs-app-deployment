include "root" {
  path = find_in_parent_folders("root.tf")
}

include "common" {
  path = "../../../../../../common/eks-cluster-config.hcl"
}

dependency "eks-cluster" {
  config_path = "../eks-cluster"
}

dependency "vpc" {
  config_path = "../vpc"
}

terraform {
  source = "../../../../..//modules/eks-cluster-config"
}

# Inputs get merged with the one from "common/"
inputs = {
  eks_cluster_oidc_url      = dependency.eks-cluster.outputs.cluster_oidc_issuer_url
  eks_cluster_oidc_arn      = dependency.eks-cluster.outputs.oidc_provider_arn
  eks_cluster_name          = dependency.eks-cluster.outputs.cluster_name
  eks_cluster_endpoint      = dependency.eks-cluster.outputs.cluster_endpoint
  eks_cluster_karpenter_iam = dependency.eks-cluster.outputs.eks_managed_node_groups["karpenter"].iam_role_name
  eks_cluster_ca            = dependency.eks-cluster.outputs.cluster_certificate_authority_data

  vpc_id = dependency.vpc.outputs.vpc_id
  
  backend_max_cpu                    = "100"
  eks_cluster_backend_instance_types = ["c7g.2xlarge", "c7g.xlarge", "c7g.large", "c7g.medium", "m7g.2xlarge", "m7g.xlarge", "m7g.large", "m7g.medium"]
}
