data "aws_iam_policy_document" "oidc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.eks_cluster_oidc_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.serviceaccount}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_cluster_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [
        var.eks_cluster_oidc_arn
      ]
      type = "Federated"
    }
  }
}
