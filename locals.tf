locals {
  # Determine the bucket identifier for use in resource references
  bucket_id = aws_s3_bucket.this.id

  # Common tags applied to all resources
  common_tags = merge(
    {
      "ManagedBy" = "terraform"
      "Module"    = "terraform-aws-s3-bucket"
    },
    var.tags,
  )

  # Determine whether to attach any bucket policy
  attach_policy = var.enforce_tls || var.bucket_policy != null

  # Build the combined bucket policy
  # When both TLS enforcement and a custom policy are provided, merge them
  bucket_policy = local.attach_policy ? (
    var.enforce_tls && var.bucket_policy != null ? data.aws_iam_policy_document.combined[0].json :
    var.enforce_tls ? data.aws_iam_policy_document.tls_enforcement[0].json :
    var.bucket_policy
  ) : null

  # Determine if event notifications are configured
  has_notifications = (
    length(var.event_notifications.lambda_functions) > 0 ||
    length(var.event_notifications.sqs_queues) > 0 ||
    length(var.event_notifications.sns_topics) > 0
  )
}
