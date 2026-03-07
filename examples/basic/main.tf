################################################################################
# Basic S3 Bucket Example
# Creates an encrypted, versioned bucket with public access blocked and TLS
# enforcement. This represents the minimum recommended security configuration.
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "s3_bucket" {
  source = "github.com/kogunlowo123/terraform-aws-s3-bucket"

  bucket_name       = "my-secure-bucket-example"
  enable_versioning = true
  enable_encryption = true
  block_public_access = true
  enforce_tls         = true

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

output "bucket_id" {
  value = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  value = module.s3_bucket.bucket_arn
}
