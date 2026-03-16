variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  default     = null
}

variable "bucket_prefix" {
  description = "Prefix for a unique bucket name (conflicts with bucket_name)"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = "Enable MFA delete on the bucket"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable server-side encryption on the bucket"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of a KMS key for SSE-KMS encryption (null for AES-256)"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable server access logging"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for object transitions and expiration"
  type = list(object({
    id      = string
    enabled = bool
    prefix  = optional(string, "")
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration = optional(object({
      days = number
    }), null)
    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_expiration = optional(object({
      days = number
    }), null)
  }))
  default = []
}

variable "enable_replication" {
  description = "Enable cross-region or same-region replication"
  type        = bool
  default     = false
}

variable "replication_role_arn" {
  description = "IAM role ARN for S3 replication"
  type        = string
  default     = null
}

variable "replication_rules" {
  description = "List of replication rules"
  type = list(object({
    id                        = string
    status                    = string
    priority                  = optional(number, 0)
    prefix                    = optional(string, "")
    destination_bucket        = string
    destination_storage_class = optional(string, "STANDARD")
    replicate_delete_markers  = optional(bool, true)
  }))
  default = []
}

variable "enable_object_lock" {
  description = "Enable S3 Object Lock (WORM protection)"
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Default Object Lock retention mode (GOVERNANCE or COMPLIANCE)"
  type        = string
  default     = "GOVERNANCE"
}

variable "object_lock_days" {
  description = "Default number of days to lock objects"
  type        = number
  default     = 30
}

variable "cors_rules" {
  description = "List of CORS rules for the bucket"
  type = list(object({
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Index document for website hosting"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for website hosting"
  type        = string
  default     = "error.html"
}

variable "event_notifications" {
  description = "S3 event notification configuration for Lambda, SQS, and SNS"
  type = object({
    lambda_functions = optional(list(object({
      id            = string
      arn           = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), [])
    sqs_queues = optional(list(object({
      id            = string
      arn           = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), [])
    sns_topics = optional(list(object({
      id            = string
      arn           = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), [])
  })
  default = {
    lambda_functions = []
    sqs_queues       = []
    sns_topics       = []
  }
}

variable "access_points" {
  description = "Map of S3 Access Point configurations"
  type = map(object({
    name   = string
    vpc_id = optional(string, null)
    policy = optional(string, null)
  }))
  default = {}
}

variable "bucket_policy" {
  description = "JSON bucket policy document to attach to the bucket"
  type        = string
  default     = null
}

variable "enforce_tls" {
  description = "Enforce TLS/HTTPS for all bucket requests"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
