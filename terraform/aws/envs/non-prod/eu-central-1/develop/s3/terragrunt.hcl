include "root" {
  path = find_in_parent_folders("root.tf")
}

locals {
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.tf"))

  # Extract the variables we need for easy access
  region      = local.region_vars.locals.region
  environment = local.environment_vars.locals.environment
}


terraform {
  source = "../../../../..//modules/storage-s3"
}

# Inputs get merged with the one from "common/"
inputs = {
  buckets_info = [{
    name   = "sample-nodejs-${local.environment}"
    public = false
  }]
}
