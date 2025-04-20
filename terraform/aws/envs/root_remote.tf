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
  # before_hook "tfsec_hook" {
  #   commands = ["apply", "plan"]
  #   execute  = ["tfsec", "."]
  # }

  after_hook "tflint_hook" {
    commands = ["validate"]
    execute = [
      "sh", "-c", <<EOT
        echo "Run tflint for project '${path_relative_to_include()}'..."
        (tflint --config="${find_in_parent_folders(".tflint.hcl")}")
        error_code=$?
        exit $error_code
      EOT
    ]
  }
}

# Generate a GCP provider block
generate "provider" {
  path      = "main.provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

terraform {
  required_version = "~> 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.44.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
    tls = {
      source = "hashicorp/tls"
      version = ">=4.0.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">=3.6.0"
    }
  }
}

provider "aws" {
  region  = "${local.region}"

  default_tags {
    tags = local.default_tags
  }
}

# Fix for public ecr only supported in us-east-1
provider "aws" {
  region  = "us-east-1"
  alias   = "virginia"
}
EOF
}

generate "locals" {
  path      = "main.locals.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
module "default_tagging" {
  # tflint-ignore: terraform_module_pinned_source
  source      = "git::git@github.com:shashwat0309/nextapp-infrastructure.git//aws/modules/default-tagging"
  environment = "${local.environment}"
  region      = "${local.region}"
}

locals {
  # tflint-ignore: terraform_unused_declarations
  environment = "${local.environment}"
  
  # tflint-ignore: terraform_unused_declarations
  cluster_name = module.default_tagging.cluster_name

  # tflint-ignore: terraform_unused_declarations
  default_tags = module.default_tagging.default_tags
  
  # tflint-ignore: terraform_unused_declarations
  region       = "${local.region}"
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in a bucket & state in dynamoDB
# This config will automatically create the resources (S3 + dynamoDB)
# It will create 1 S3 bucket with 1 folder for each `aws/envs/` folder
# It will generate the backend.tf for each `aws/envs/` folder
remote_state {
  backend = "s3"
  config = {
    bucket         = "nextapp-infrastructure-tfstate"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "tfstate-lock"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.environment_vars.locals,
  local.region_vars.locals,
)
