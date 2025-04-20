variable "buckets_info" {
  type = list(object({
    name   = string
    public = bool
  }))
}

variable "thanos_bucket_roles" {
  description = "List of IAM role ARNs that need access to the Thanos bucket"
  type        = list(string)
  default     = []
}

variable "enable_thanos_bucket_policy" {
  description = "Whether to enable the Thanos bucket policy"
  type        = bool
  default     = false
}
