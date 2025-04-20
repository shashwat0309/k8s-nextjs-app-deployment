################################################################################
# Main Cluster Configuration
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  create_kms_key = true
  kms_key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/infra-deployer",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/infra-reader",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevOpsRole",
  ]
  kms_key_description           = "KMS Secrets encryption for EKS ${local.cluster_name} cluster."
  kms_key_enable_default_policy = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  enable_irsa = true

  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_private_subnets

  # EKS Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent                 = true
      service_account_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_name}-ebs-csi-controller"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    coredns = {
      most_recent  = true
      replicaCount = "5"
    }

    eks-node-monitoring-agent = {
      most_recent = true
    }

    # amazon-cloudwatch-observability = {
    #   most_recent              = true
    #   service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_name}-cloudwatch-obs"
    #   containerlogs = jsonencode({
    #     enabled = "false"
    #   })

    #   configuration_values = jsonencode({
    #     agent = {
    #       config = {
    #         logs = {
    #           metrics_collected = {
    #             kubernetes = {
    #               enhanced_container_insights = "true"
    #               accelerated_compute_metrics = "false"
    #             }
    #           }
    #         }
    #       }
    #     }
    #   })
    # }
  }

  eks_managed_node_group_defaults = {
    ami_type           = "BOTTLEROCKET_ARM_64"
    platform           = "bottlerocket"
    launch_template_os = "bottlerocket"

    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    use_custom_launch_template = false
    create_launch_template     = true

    update_config = {
      max_unavailable = 1
    }

    disk_size     = 128
    ebs_optimized = true

    disable_api_termination = false
    enable_monitoring       = true
    force_update_version    = true

    enabled_cluster_log_types = [] # ["api", "audit"]

    iam_role_additional_policies = {
      # Required by Karpenter
      AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      # CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
  }

  eks_managed_node_groups = {
    karpenter = {
      instance_types = ["m7g.large"]

      min_size     = 3
      max_size     = 4
      desired_size = 3

      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"

        # [settings.kubernetes.node-labels]
        type = karpenter

        # [settings.kubernetes.node-taints]
        dedicated = "experimental:PreferNoSchedule"
        special = "true:NoSchedule"

        # extra args added
        [settings.kubernetes]
        container-log-max-size = "50Mi"
        container-log-max-files = 3
        image-gc-high-threshold-percent = 75
        image-gc-low-threshold-percent = 70
      EOT

      taints = {
        # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
        # The pods that do not tolerate this taint should run on nodes created by Karpenter
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        },
      }

      tags = {
        type                     = "karpenter"
        "karpenter.sh/discovery" = local.cluster_name
      }
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # Update the aws-auth ConfigMap in the cluster to allow the nodes that use the
    # KarpenterInstanceNodeRole IAM role to join the cluster
    # {
    #   rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterInstanceNodeRole-${var.cluster_name}"
    #   username = "system:node:{{EC2PrivateDNSName}}"
    #   groups = [
    #     "system:bootstrappers",
    #     "system:nodes",
    #   ]
    # },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevelopersRole"
      username = "nextapp-dev"
      groups : ["nextapp-dev"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/infra-reader"
      username = "infra-reader"
      groups : ["nextapp-dev"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DevOpsRole"
      username = "nextapp-devops"
      groups : ["nextapp-devops"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/infra-deployer"
      username = "infra-deployer"
      groups : ["nextapp-devops"]
    },
  ]
}

// create role to attach to the nodes through the aws-ebs-csi-driver
resource "aws_iam_policy" "ebs_csi_controller" {
  name_prefix = "ebs-csi-controller"
  description = "EKS ebs-csi-controller policy for cluster ${local.cluster_name}"
  policy      = file("${path.module}/policies/ebs_csi_controller_iam_policy.json")
}
// https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-assumable-role-with-oidc
module "ebs_csi_controller_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.20.0"
  create_role                   = true
  role_name                     = "${local.cluster_name}-ebs-csi-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.ebs_csi_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

// create role for cloudwatch observability
# resource "aws_iam_policy" "cloudwatch_observability" {
#   name_prefix = "cloudwatch-observability"
#   description = "EKS cloudwatch observability policy for cluster ${local.cluster_name}"
#   policy      = file("${path.module}/policies/cloudwatch_monitoring.json")
# }

# module "cloudwatch_obs_role" {
#   source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version                       = "5.20.0"
#   create_role                   = true
#   role_name                     = "${local.cluster_name}-cloudwatch-obs"
#   provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
#   role_policy_arns              = [aws_iam_policy.cloudwatch_observability.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
# }
