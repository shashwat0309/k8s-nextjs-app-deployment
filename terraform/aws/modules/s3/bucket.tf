locals {
  bucket_list = toset(var.buckets)
}

resource "aws_s3_bucket" "bucket" {
  for_each = local.bucket_list
  bucket   = each.value
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  for_each = local.bucket_list
  bucket   = aws_s3_bucket.bucket[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  for_each = local.bucket_list
  bucket   = aws_s3_bucket.bucket[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "bucket" {
  for_each = local.bucket_list
  bucket   = aws_s3_bucket.bucket[each.key].bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}
