module "test" {
  source = "../"

  bucket_prefix = "test-s3-bucket-"

  # Versioning
  enable_versioning = true
  mfa_delete        = false

  # Encryption
  enable_encryption = true

  # Public Access Block
  block_public_access = true

  # Enforce TLS
  enforce_tls = true

  # Lifecycle Rules
  lifecycle_rules = [
    {
      id      = "transition-to-ia"
      enabled = true
      prefix  = ""
      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 365
      }
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]

  # Static Website Hosting (disabled)
  enable_website = false

  # Force Destroy (enabled for test)
  force_destroy = true

  tags = {
    Project     = "s3-bucket-test"
    Environment = "test"
  }
}
