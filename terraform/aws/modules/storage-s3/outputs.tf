output "bucket_names" {
  description = "Names of the created S3 buckets"
  value = {
    for k, v in aws_s3_bucket.bucket : k => v.id
  }
}

output "bucket_policies" {
  description = "The rendered bucket policies"
  value = {
    for k, v in aws_s3_bucket_policy.thanos_bucket_policy : k => jsondecode(v.policy)
  }
}
