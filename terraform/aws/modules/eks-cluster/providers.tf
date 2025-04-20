// The EKS module need to connect to the cluster 

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    # To be swapped for cluster creation
    # args = ["eks", "get-token", "--region", local.region, "--cluster-name", module.eks.cluster_name]
    args = ["eks", "get-token", "--role", "arn:aws:iam::403372804574:role/DevOpsRole", "--region", local.region, "--cluster-name", module.eks.cluster_name]
  }
}

provider "kubectl" {
  apply_retry_count      = 3
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    # To be swapped for cluster creation
    # args = ["eks", "get-token", "--region", local.region, "--cluster-name", module.eks.cluster_name]
    args = ["eks", "get-token", "--role", "arn:aws:iam::403372804574:role/DevOpsRole", "--region", local.region, "--cluster-name", module.eks.cluster_name]
  }
}
