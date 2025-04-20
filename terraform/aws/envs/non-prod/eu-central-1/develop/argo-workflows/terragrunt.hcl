include "root" {
  path = find_in_parent_folders("root.tf")
}

dependency "eks-cluster" {
  config_path = "../eks-cluster"
}

terraform {
  source = "../../../../..//modules/argo-workflows"
}

inputs = {
  bucket_prefix        = "argowf-artifacts"
  eks_cluster_oidc_arn = dependency.eks-cluster.outputs.oidc_provider_arn
  eks_cluster_oidc_url = dependency.eks-cluster.outputs.oidc_provider
}
