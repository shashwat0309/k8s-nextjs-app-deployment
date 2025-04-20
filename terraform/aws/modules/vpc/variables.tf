variable "cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "one_nat_gateway_per_az" {
  type    = bool
  default = false
}
