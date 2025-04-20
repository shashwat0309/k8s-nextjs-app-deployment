variable "eks_cluster_oidc_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}
variable "eks_cluster_oidc_url" {
  description = "The URL of the cluster OIDC Provider (URL/id/CLUSTER_ID)"
  type        = string
}
variable "vault_ns" {
  type    = string
  default = "vault"
}
variable "vault_sa" {
  type    = string
  default = "vault"
}
