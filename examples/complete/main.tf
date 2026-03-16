provider "aws" {
  region = "us-east-1"
}

module "log_bucket" {
  source = "../../"

  bucket_name       = "my-app-logs-example"
  enable_versioning = true
  enforce_tls       = true

  tags = {
    Environment = "production"
    Purpose     = "logging"
  }
}

module "s3_bucket" {
  source = "../../"

  bucket_name   = "my-app-bucket-example"
  force_destroy = false

  # Versioning
  enable_versioning = true

  # KMS Encryption
  enable_encryption = true
  kms_key_arn       = aws_kms_key.s3.arn

  # Public access
  block_public_access = true

  # Logging
  enable_logging        = true
  logging_target_bucket = module.log_bucket.bucket_id
  logging_target_prefix = "access-logs/"

  # Lifecycle
  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      prefix  = ""
      transitions = [
        { days = 90, storage_class = "STANDARD_IA" },
        { days = 180, storage_class = "GLACIER" },
      ]
      expiration = { days = 365 }
    },
  ]

  # CORS
  cors_rules = [
    {
      allowed_methods = ["GET", "PUT"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["*"]
    },
  ]

  # TLS enforcement
  enforce_tls = true

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}

resource "aws_kms_key" "s3" {
  description         = "KMS key for S3 bucket encryption"
  enable_key_rotation = true
}

output "bucket_id" {
  value = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  value = module.s3_bucket.bucket_arn
}
