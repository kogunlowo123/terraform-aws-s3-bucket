################################################################################
# Complete S3 Bucket Example
# Demonstrates all module features: encryption, versioning, lifecycle, logging,
# replication, object lock, CORS, website hosting, event notifications, access
# points, and custom bucket policies.
################################################################################

provider "aws" {
  region = "us-east-1"
}

################################################################################
# KMS Key for Encryption
################################################################################

resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "production"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3-bucket-key"
  target_key_id = aws_kms_key.s3.key_id
}

################################################################################
# Log Bucket
################################################################################

module "log_bucket" {
  source = "github.com/kogunlowo123/terraform-aws-s3-bucket"

  bucket_name       = "my-complete-example-logs"
  enable_versioning = true
  enable_encryption = true
  enforce_tls       = true

  lifecycle_rules = [
    {
      id      = "expire-logs"
      enabled = true
      prefix  = ""
      transitions = [
        { days = 90, storage_class = "GLACIER" },
      ]
      expiration = { days = 365 }
    },
  ]

  tags = {
    Environment = "production"
    Purpose     = "logging"
  }
}

################################################################################
# SNS Topic for Notifications
################################################################################

resource "aws_sns_topic" "s3_events" {
  name = "s3-event-notifications"
}

resource "aws_sns_topic_policy" "s3_events" {
  arn = aws_sns_topic.s3_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Publish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.s3_events.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = module.complete_bucket.bucket_arn
          }
        }
      },
    ]
  })
}

################################################################################
# SQS Queue for Notifications
################################################################################

resource "aws_sqs_queue" "s3_events" {
  name                       = "s3-event-queue"
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue_policy" "s3_events" {
  queue_url = aws_sqs_queue.s3_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.s3_events.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = module.complete_bucket.bucket_arn
          }
        }
      },
    ]
  })
}

################################################################################
# VPC for Access Point
################################################################################

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "s3-access-point-vpc"
  }
}

################################################################################
# Custom Bucket Policy
################################################################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "custom" {
  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      module.complete_bucket.bucket_arn,
      "${module.complete_bucket.bucket_arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

################################################################################
# Complete S3 Bucket
################################################################################

module "complete_bucket" {
  source = "github.com/kogunlowo123/terraform-aws-s3-bucket"

  bucket_name   = "my-complete-example-bucket"
  force_destroy = false

  # Versioning
  enable_versioning = true
  mfa_delete        = false

  # KMS Encryption
  enable_encryption = true
  kms_key_arn       = aws_kms_key.s3.arn

  # Public access block
  block_public_access = true

  # Access logging
  enable_logging        = true
  logging_target_bucket = module.log_bucket.bucket_id
  logging_target_prefix = "access-logs/complete-bucket/"

  # Lifecycle rules with Intelligent Tiering
  lifecycle_rules = [
    {
      id      = "intelligent-tiering-all"
      enabled = true
      prefix  = ""
      transitions = [
        {
          days          = 0
          storage_class = "INTELLIGENT_TIERING"
        },
      ]
    },
    {
      id      = "archive-documents"
      enabled = true
      prefix  = "documents/"
      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        },
      ]
      expiration = {
        days = 2555
      }
      noncurrent_version_transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        },
      ]
      noncurrent_version_expiration = {
        days = 90
      }
    },
    {
      id      = "cleanup-temp"
      enabled = true
      prefix  = "temp/"
      expiration = {
        days = 7
      }
    },
  ]

  # CORS rules
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = ["https://example.com", "https://app.example.com"]
      expose_headers  = ["ETag", "x-amz-request-id"]
      max_age_seconds = 3600
    },
  ]

  # Event notifications
  event_notifications = {
    sns_topics = [
      {
        id            = "notify-on-create"
        arn           = aws_sns_topic.s3_events.arn
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "uploads/"
        filter_suffix = null
      },
    ]
    sqs_queues = [
      {
        id            = "queue-on-delete"
        arn           = aws_sqs_queue.s3_events.arn
        events        = ["s3:ObjectRemoved:*"]
        filter_prefix = null
        filter_suffix = null
      },
    ]
    lambda_functions = []
  }

  # Access points
  access_points = {
    vpc_restricted = {
      name   = "my-vpc-access-point"
      vpc_id = aws_vpc.example.id
      policy = null
    }
  }

  # Bucket policy (TLS enforcement is automatic)
  bucket_policy = data.aws_iam_policy_document.custom.json
  enforce_tls   = true

  tags = {
    Environment = "production"
    Project     = "complete-example"
    CostCenter  = "engineering"
    Owner       = "platform-team"
  }
}

################################################################################
# Outputs
################################################################################

output "bucket_id" {
  value = module.complete_bucket.bucket_id
}

output "bucket_arn" {
  value = module.complete_bucket.bucket_arn
}

output "bucket_domain_name" {
  value = module.complete_bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  value = module.complete_bucket.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  value = module.complete_bucket.bucket_hosted_zone_id
}
