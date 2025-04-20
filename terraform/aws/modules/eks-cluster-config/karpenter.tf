# Configure the IAM role for the Karpenter controller and associate to the cluster oidc provider
module "iam_assumable_role_karpenter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.20.0"
  create_role                   = true
  role_name                     = "KarpenterControllerRole-${local.cluster_name}"
  provider_url                  = var.eks_cluster_oidc_url
  oidc_fully_qualified_subjects = ["system:serviceaccount:karpenter:karpenter"]
}

# Configure the policy for the Karpenter controller IAM role
resource "aws_iam_role_policy" "karpenter_controller" {
  name   = "KarpenterControllerPolicy-${local.cluster_name}"
  role   = module.iam_assumable_role_karpenter.iam_role_name
  policy = file("${path.module}/policies/karpenter_controller_iam_policy.json")
}

################################################################################
# Karpenter - Helm Chart
################################################################################

resource "helm_release" "karpenter_crd" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = "v0.32.1"
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.32.1"

  values = [
    <<-EOT
      serviceMonitor:
        enabled: true
        additionalLabels:
          release: prometheus
      controller:
        resources:
          requests:
            memory: "256M"
          limits:
            memory: "1Gi"
      settings:
        aws:
          clusterName: ${var.eks_cluster_name}
          clusterEndpoint: ${var.eks_cluster_endpoint}
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: ${module.iam_assumable_role_karpenter.iam_role_arn}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: karpenter.sh/nodepool
                    operator: DoesNotExist
    EOT
  ]

  depends_on = [
    module.iam_assumable_role_karpenter,
    helm_release.karpenter_crd
  ]
}

################################################################################
# Karpenter - NodePools and NodeClasses
################################################################################

resource "helm_release" "karpenter_backend_np" {
  name       = "karpenter-backend-nodepool"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.sh/v1beta1
        kind: NodePool
        metadata:
          name: backend-np
        spec:
          limits:
            cpu: ${var.backend_max_cpu}
          disruption:
            consolidationPolicy: WhenUnderutilized
            expireAfter: 720h
          template:
            metadata:
              labels:
                type: backend
            spec:
              nodeClassRef:
                name: backend-nc
              requirements:
                - key: karpenter.sh/capacity-type
                  operator: In
                  values: ["on-demand"]
                - key: kubernetes.io/os
                  operator: In
                  values: ["linux"]
                - key: kubernetes.io/arch
                  operator: In
                  values: ["arm64"]
                - key: type
                  operator: In
                  values: ["backend"]
                - key: node.kubernetes.io/instance-type
                  operator: In
                  values: ${jsonencode(setunion(var.eks_cluster_backend_instance_types))}
    EOF
  ]
  depends_on = [
    helm_release.karpenter_crd,
    helm_release.karpenter
  ]
}
resource "helm_release" "karpenter_ci_np" {
  count      = var.has_ci_nodes ? 1 : 0
  name       = "karpenter-ci-nodepool"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.sh/v1beta1
        kind: NodePool
        metadata:
          name: ci-np
        spec:
          limits:
            cpu: ${var.ci_max_cpu}
          disruption:
            consolidationPolicy: WhenUnderutilized
            expireAfter: 720h
          template:
            metadata:
              labels:
                type: ci
            spec:
              nodeClassRef:
                name: ci-nc
              requirements:
                - key: karpenter.sh/capacity-type
                  operator: In
                  values: ["on-demand"]
                - key: kubernetes.io/os
                  operator: In
                  values: ["linux"]
                - key: kubernetes.io/arch
                  operator: In
                  values: ["arm64"]
                - key: type
                  operator: In
                  values: ["ci"]
                - key: node.kubernetes.io/instance-type
                  operator: In
                  values: ${jsonencode(setunion(var.eks_cluster_ci_instance_types))}
    EOF
  ]
  depends_on = [
    helm_release.karpenter_crd,
    helm_release.karpenter
  ]
}
resource "helm_release" "karpenter_data_np" {
  count      = var.has_data_nodes ? 1 : 0
  name       = "karpenter-data-nodepool"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.sh/v1beta1
        kind: NodePool
        metadata:
          name: data-np
        spec:
          limits:
            cpu: ${var.data_max_cpu}
          disruption:
            consolidationPolicy: WhenUnderutilized
            expireAfter: 720h
          template:
            metadata:
              labels:
                type: data
            spec:
              nodeClassRef:
                name: data-nc
              requirements:
                - key: karpenter.sh/capacity-type
                  operator: In
                  values: ["on-demand"]
                - key: kubernetes.io/os
                  operator: In
                  values: ["linux"]
                - key: kubernetes.io/arch
                  operator: In
                  values: ["arm64"]
                - key: type
                  operator: In
                  values: ["data"]
                - key: node.kubernetes.io/instance-type
                  operator: In
                  values: ${jsonencode(setunion(var.eks_cluster_data_instance_types))}
    EOF
  ]
  depends_on = [
    helm_release.karpenter_crd,
    helm_release.karpenter
  ]
}

resource "helm_release" "karpenter_backend_nc" {
  name       = "karpenter-backend-node-class"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        metadata:
          name: backend-nc
        spec:
          amiFamily: Bottlerocket
          blockDeviceMappings:
            - deviceName: /dev/xvdb
              ebs:
                volumeSize: 50Gi
                volumeType: gp3
                deleteOnTermination: true
                encrypted: true 
          metadataOptions:
            httpEndpoint: enabled
            httpProtocolIPv6: disabled
            httpPutResponseHopLimit: 2
            httpTokens: required
          tags:
            karpenter.sh/discovery: ${var.eks_cluster_name}
          role: ${var.eks_cluster_karpenter_iam}
          subnetSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
          securityGroupSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
    EOF
  ]
}
resource "helm_release" "karpenter_ci_nc" {
  count      = var.has_ci_nodes ? 1 : 0
  name       = "karpenter-ci-node-class"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        metadata:
          name: ci-nc
        spec:
          amiFamily: Bottlerocket
          metadataOptions:
            httpEndpoint: enabled
            httpProtocolIPv6: disabled
            httpPutResponseHopLimit: 2
            httpTokens: required
          tags:
            karpenter.sh/discovery: ${var.eks_cluster_name}
          role: ${var.eks_cluster_karpenter_iam}
          subnetSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
          securityGroupSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
    EOF
  ]
}
resource "helm_release" "karpenter_data_nc" {
  count      = var.has_data_nodes ? 1 : 0
  name       = "karpenter-data-node-class"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        metadata:
          name: data-nc
        spec:
          amiFamily: Bottlerocket
          blockDeviceMappings:
            - deviceName: /dev/xvda
              ebs:
                volumeSize: 100Gi
                volumeType: gp3
                deleteOnTermination: true
                encrypted: true 
          metadataOptions:
            httpEndpoint: enabled
            httpProtocolIPv6: disabled
            httpPutResponseHopLimit: 2
            httpTokens: required
          tags:
            karpenter.sh/discovery: ${var.eks_cluster_name}
          role: ${var.eks_cluster_karpenter_iam}
          subnetSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
          securityGroupSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
    EOF
  ]
}

// dynamic partner nodes
resource "helm_release" "karpenter_extra_np" {
  for_each = {
    for k in var.extra_nodes : k.name => k.max_cpu
    if var.has_extra_nodes == true
  }
  name       = "karpenter-${each.key}-nodepool"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.sh/v1beta1
        kind: NodePool
        metadata:
          name: ${each.key}-np
        spec:
          limits:
            cpu: ${each.value}
          disruption:
            consolidationPolicy: WhenUnderutilized
            expireAfter: 720h
          template:
            metadata:
              labels:
                type: ${each.key}
            spec:
              nodeClassRef:
                name: ${each.key}-nc
              requirements:
                - key: karpenter.sh/capacity-type
                  operator: In
                  values: ["on-demand"]
                - key: kubernetes.io/os
                  operator: In
                  values: ["linux"]
                - key: kubernetes.io/arch
                  operator: In
                  values: ["arm64"]
                - key: type
                  operator: In
                  values: [${jsonencode(each.key)}]
                - key: node.kubernetes.io/instance-type
                  operator: In
                  values: ${jsonencode(setunion(var.eks_cluster_backend_instance_types))}
    EOF
  ]
  depends_on = [
    helm_release.karpenter_crd,
    helm_release.karpenter
  ]
}

resource "helm_release" "karpenter_extra_nc" {
  for_each = {
    for k in var.extra_nodes : k.name => k
    if var.has_extra_nodes == true
  }
  name       = "karpenter-${each.key}-node-class"
  repository = "https://bedag.github.io/helm-charts/"
  chart      = "raw"
  version    = "2.0.0"
  values = [
    <<-EOF
    resources:
      - apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        metadata:
          name: ${each.key}-nc
        spec:
          amiFamily: Bottlerocket
          blockDeviceMappings:
            - deviceName: /dev/xvdb
              ebs:
                volumeSize: 50Gi
                volumeType: gp3
                deleteOnTermination: true
                encrypted: true
          metadataOptions:
            httpEndpoint: enabled
            httpProtocolIPv6: disabled
            httpPutResponseHopLimit: 2
            httpTokens: required
          tags:
            karpenter.sh/discovery: ${var.eks_cluster_name}
          role: ${var.eks_cluster_karpenter_iam}
          subnetSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
          securityGroupSelectorTerms:
          - tags:
              karpenter.sh/discovery: ${var.eks_cluster_name}
    EOF
  ]
}
