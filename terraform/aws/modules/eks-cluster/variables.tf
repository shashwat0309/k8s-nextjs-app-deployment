variable "cluster_version" {
  type    = string
  default = "1.28"
}

variable "vpc_id" {
  type = string
}
variable "vpc_private_subnets" {
  type    = list(string)
  default = []
}
