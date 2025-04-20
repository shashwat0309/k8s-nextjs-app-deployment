locals {
  buckets_name = toset([for k in var.buckets_info : k.name])
  buckets_info = [for k in var.buckets_info : {
    name   = k.name
    public = k.public
  }]
}

resource "aws_s3_bucket" "bucket" {
  for_each = local.buckets_name
  bucket   = each.value
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  for_each = local.buckets_name
  bucket   = aws_s3_bucket.bucket[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  for_each = { for k in local.buckets_info : k.name => k }
  bucket   = aws_s3_bucket.bucket[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "pb" {
  for_each = {
    for k in var.buckets_info : k.name => k
    if k.public == true
  }
  bucket = aws_s3_bucket.bucket[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "public" {
  for_each = {
    for k in var.buckets_info : k.name => k
    if k.public == true
  }

  bucket = aws_s3_bucket.bucket[each.key].id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.bucket,
    aws_s3_bucket_public_access_block.pb,
  ]
}

resource "aws_s3_bucket_policy" "thanos_bucket_policy" {
  for_each = {
    for k in local.buckets_info : k.name => k
    if var.enable_thanos_bucket_policy
  }
  bucket = aws_s3_bucket.bucket[each.key].id
  depends_on = [aws_s3_bucket_ownership_controls.bucket]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid"    = "ThanosAccess"
        "Effect" = "Allow"
        "Principal" = {
          "AWS" = var.thanos_bucket_roles
        }
        "Action" = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        "Resource" = [
          "${aws_s3_bucket.bucket[each.key].arn}/*",
          aws_s3_bucket.bucket[each.key].arn
        ]
      }
    ]
  })
}
