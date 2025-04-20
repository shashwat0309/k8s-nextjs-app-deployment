resource "aws_iam_account_password_policy" "strict" {
  allow_users_to_change_password = true
  max_password_age               = 180
  password_reuse_prevention      = 2

  minimum_password_length      = 16
  require_lowercase_characters = true
  require_numbers              = true
  require_uppercase_characters = true
  require_symbols              = true
}
