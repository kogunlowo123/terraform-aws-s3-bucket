################################################################################
# Advanced S3 Bucket Example
# Creates a bucket with lifecycle rules, access logging, and cross-region
# replication. Demonstrates cost-optimized storage tiering and data protection.
################################################################################

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "replica"
  region = "us-west-2"
}

################################################################################
# Logging Target Bucket
################################################################################

module "log_bucket" {
  source = "github.com/kogunlowo123/terraform-aws-s3-bucket"

  bucket_name       = "my-app-access-logs-example"
  enable_versioning = true
  enable_encryption = true
  enforce_tls       = true

  lifecycle_rules = [
    {
      id      = "log-expiration"
      enabled = true
      prefix  = ""
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]
      expiration = {
        days = 365
      }
    },
  ]

  tags = {
    Environment = "production"
    Purpose     = "access-logging"
  }
}

################################################################################
# Replication Destination Bucket
################################################################################

module "replica_bucket" {
  source = "github.com/kogunlowo123/terraform-aws-s3-bucket"

  providers = {
    aws = aws.replica
  }

  bucket_name       = "my-app-data-replica-example"
  enable_versioning = true
  enable_encryption = true
  enforce_tls       = true

  tags = {
    Environment = "production"
    Purpose     = "replication-destination"
  }
}

################################################################################
# IAM Role for Replication
################################################################################

data "aws_iam_policy_document" "replication_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "s3-replication-role-example"
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [module.primary_bucket.bucket_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${module.primary_bucket.bucket_arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${module.replica_bucket.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "s3-replication-policy"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication.json
}

################################################################################
# Primary Application Bucket
################################################################################

module "primary_bucket" {
  source = "github.com/kogunlowo123/terraform-aws-s3-bucket"

  bucket_name       = "my-app-data-primary-example"
  enable_versioning = true
  enable_encryption = true
  enforce_tls       = true

  # Access logging
  enable_logging        = true
  logging_target_bucket = module.log_bucket.bucket_id
  logging_target_prefix = "s3-access-logs/primary/"

  # Lifecycle rules with Intelligent Tiering
  lifecycle_rules = [
    {
      id      = "intelligent-tiering"
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
      id      = "archive-old-versions"
      enabled = true
      prefix  = ""
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
        days = 180
      }
    },
  ]

  # Cross-region replication
  enable_replication   = true
  replication_role_arn = aws_iam_role.replication.arn
  replication_rules = [
    {
      id                 = "replicate-all"
      status             = "Enabled"
      priority           = 1
      destination_bucket = module.replica_bucket.bucket_arn
    },
  ]

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}

################################################################################
# Outputs
################################################################################

output "primary_bucket_id" {
  value = module.primary_bucket.bucket_id
}

output "primary_bucket_arn" {
  value = module.primary_bucket.bucket_arn
}

output "replica_bucket_arn" {
  value = module.replica_bucket.bucket_arn
}
