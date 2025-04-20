locals {
  registry_list = toset(var.registries)
}

resource "aws_ecr_repository" "registry" {
  for_each             = local.registry_list
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}
