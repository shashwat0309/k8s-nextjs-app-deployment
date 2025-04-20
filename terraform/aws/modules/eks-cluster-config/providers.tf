provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_ca)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      # To be swapped for cluster creation
      # args = ["eks", "get-token", "--region", local.region, "--cluster-name", local.cluster_name]
      args = ["eks", "get-token", "--role", "arn:aws:iam::403372804574:role/DevOpsRole", "--region", local.region, "--cluster-name", local.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    # To be swapped for cluster creation
    # args = ["eks", "get-token", "--region", local.region, "--cluster-name", local.cluster_name]
    args = ["eks", "get-token", "--role", "arn:aws:iam::403372804574:role/DevOpsRole", "--region", local.region, "--cluster-name", local.cluster_name]
  }
}

provider "kubectl" {
  apply_retry_count      = 3
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    # To be swapped for cluster creation
    # args = ["eks", "get-token", "--region", local.region, "--cluster-name", local.cluster_name]
    args = ["eks", "get-token", "--role", "arn:aws:iam::403372804574:role/DevOpsRole", "--region", local.region, "--cluster-name", local.cluster_name]
  }
}
