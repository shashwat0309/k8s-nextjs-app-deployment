locals {
  cluster_name = var.environment == "prod" ? "nextapp-${var.environment}-${var.region}" : "nextapp-${var.environment}"

  default_tags = {
    application   = local.cluster_name
    environment   = var.environment
    repository    = "https://github.com/shashwat0309/nextapp-infrastructure"
    controlled-by = "terraform"
  }
}
