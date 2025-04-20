inputs = {
  # 8vCPU / 16Gi
  eks_cluster_backend_instance_types = ["c7g.2xlarge", "c7g.xlarge", "c7g.large", "c7g.medium"]

  # 3 instances
  backend_max_cpu = "24"
}
