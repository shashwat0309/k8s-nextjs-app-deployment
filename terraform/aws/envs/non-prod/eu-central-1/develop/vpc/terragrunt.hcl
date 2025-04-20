include "root" {
  path = find_in_parent_folders("root.tf")
}

include "common" {
  path = "../../../../../../common/vpc.hcl"
}

terraform {
  source = "../../../../..//modules/vpc"
}

# No need for inputs here, as they're all in "common/"
