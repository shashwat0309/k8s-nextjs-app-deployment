resource "aws_s3_bucket" "argowf-data" {
  bucket = "${var.bucket_prefix}-${local.environment}-${local.region}"
}

resource "aws_s3_bucket_policy" "grant-access" {
  bucket = aws_s3_bucket.argowf-data.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "Statement1",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.argowf.arn
        },
        Action : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource : [
          aws_s3_bucket.argowf-data.arn,
          "${aws_s3_bucket.argowf-data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "argowf" {
  name               = "ArgowfStorage-${local.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.oidc.json
}

resource "aws_iam_policy" "argowf" {
  name        = "ArgowfStorageAccessPolicy-${var.bucket_prefix}-${local.cluster_name}"
  path        = "/"
  description = "Allows argowf to access bucket"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource : [
          aws_s3_bucket.argowf-data.arn,
          "${aws_s3_bucket.argowf-data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argowf-attach" {
  role       = aws_iam_role.argowf.name
  policy_arn = aws_iam_policy.argowf.arn
}
