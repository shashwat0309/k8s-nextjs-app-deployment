variable "bucket_prefix" {
  description = "Bucket name for argo-workflow artifact storage"
  type        = string
}

variable "namespace" {
  description = "Namespace of argo-workflow installation"
  type        = string
  default     = "backend" # Jobs will run in the backend NS
}

variable "serviceaccount" {
  description = "Service account that will connect to the S3 bucket"
  type        = string
  default     = "argo-exec"
}

variable "eks_cluster_oidc_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}

variable "eks_cluster_oidc_url" {
  description = "The URL of the cluster OIDC Provider (URL/id/CLUSTER_ID)"
  type        = string
}
