include "root" {
  path = find_in_parent_folders("root.tf")
}

include "common" {
  path = "../../../../../../common/eks-cluster.hcl"
}

dependency "vpc" {
  config_path = "../vpc"
}

terraform {
  source = "../../../../..//modules/eks-cluster"
}

# Inputs get merged with the one from "common/"
inputs = {
  vpc_id              = dependency.vpc.outputs.vpc_id
  vpc_private_subnets = dependency.vpc.outputs.private_subnets
}
