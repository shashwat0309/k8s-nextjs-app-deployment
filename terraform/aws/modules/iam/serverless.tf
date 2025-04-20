module "serverless-user" {
  source  = "silinternational/serverless-user/aws"
  version = "0.1.0"

  app_name           = "next-app"
  aws_region         = "eu-central-1"
  enable_api_gateway = true
  extra_policies = [
    jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "s3:*",
            "sns:*",
            "logs:TagResource",
            "iam:TagRole",
            "iam:CreateRole",
            "iam:PutRolePolicy",
            "iam:GetRole",
            "iam:PassRole",
            "lambda:TagResource",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs",
            "apigateway:POST",
            "apigateway:DELETE",
            "apigateway:PATCH",
            "apigateway:TagResource",
          ],
          "Resource" : "*"
        }
      ]
    })
  ]
}
