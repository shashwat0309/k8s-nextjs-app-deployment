output "vault_iam_role_arn" {
  value       = aws_iam_role.vault_service_account_role.arn
  description = "The unique key id used by Vault"
}
output "serverless-user-access-key-id" {
  value = module.serverless-user.aws_access_key_id
}
output "serverless-user-secret-access-key" {
  value     = module.serverless-user.aws_secret_access_key
  sensitive = true
}
