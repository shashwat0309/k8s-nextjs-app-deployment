# Set common variables for the region. This is automatically pulled in in the root terragrunt.hcl configuration to
# pass forward to the child modules as inputs.
locals {
  region = "eu-central-1"
}
