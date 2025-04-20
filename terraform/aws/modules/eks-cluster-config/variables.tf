variable "eks_cluster_backend_instance_types" {
  type    = list(string)
  default = []
}
variable "eks_cluster_ci_instance_types" {
  type    = list(string)
  default = []
}
variable "eks_cluster_data_instance_types" {
  type    = list(string)
  default = ["m7g.xlarge", "m7g.large"]
}
variable "eks_cluster_oidc_url" {
  type = string
}
variable "eks_cluster_oidc_arn" {
  type = string
}
variable "eks_cluster_name" {
  type = string
}
variable "eks_cluster_endpoint" {
  type = string
}
variable "eks_cluster_karpenter_iam" {
  type = string
}
variable "eks_cluster_ca" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "backend_max_cpu" {
  type    = string
  default = "96000m"
}

variable "data_max_cpu" {
  type    = string
  default = "32000m"
}

variable "has_ci_nodes" {
  type        = bool
  default     = false
  description = "Wether the cluster has CI dedicated nodes"
}

variable "has_data_nodes" {
  type        = bool
  default     = false
  description = "Wether the cluster has CI dedicated nodes"
}
variable "ci_max_cpu" {
  type    = string
  default = "8000m"
}

variable "has_extra_nodes" {
  type        = bool
  default     = false
  description = "Wether the cluster has partner dedicated nodes"
}
variable "extra_nodes" {
  default = []
  type = list(object({
    name    = string
    max_cpu = string
  }))
}
