################################################################################
# Bucket Configuration
################################################################################

variable "bucket_name" {
  description = <<-EOT
    The name of the S3 bucket. Must be globally unique across all AWS accounts.
    If omitted, Terraform will assign a random, unique name. Conflicts with
    `bucket_prefix`. Must be between 3-63 characters, lowercase, and may contain
    hyphens and periods.
  EOT
  type        = string
  default     = null
}

variable "bucket_prefix" {
  description = <<-EOT
    Creates a unique bucket name beginning with the specified prefix. Conflicts
    with `bucket_name`. The prefix must be between 3-37 characters. Terraform
    appends a random suffix to ensure global uniqueness.
  EOT
  type        = string
  default     = null
}

variable "force_destroy" {
  description = <<-EOT
    When set to true, allows Terraform to delete the bucket even if it contains
    objects. All objects (including locked objects) will be deleted when the bucket
    is destroyed. Use with extreme caution in production environments.
    Default: false (safe deletion — bucket must be empty before destroy).
  EOT
  type        = bool
  default     = false
}

################################################################################
# Versioning
################################################################################

variable "enable_versioning" {
  description = <<-EOT
    Enable S3 bucket versioning. When enabled, S3 keeps multiple variants of an
    object in the same bucket. Versioning is required for cross-region replication,
    MFA delete, and is a CIS AWS Benchmark recommendation. Once enabled, versioning
    can only be suspended — not fully disabled.
    Default: true (recommended for data protection).
  EOT
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = <<-EOT
    Enable MFA Delete for the S3 bucket. When enabled, the bucket owner must
    include two forms of authentication in any request to delete a version or
    change the versioning state. Requires versioning to be enabled. Note: MFA
    Delete can only be enabled by the root account holder via the AWS CLI.
    Default: false.
  EOT
  type        = bool
  default     = false
}

################################################################################
# Encryption
################################################################################

variable "enable_encryption" {
  description = <<-EOT
    Enable server-side encryption for the S3 bucket. When enabled, all objects
    stored in the bucket are encrypted at rest. If `kms_key_arn` is provided,
    AWS KMS (aws:kms) encryption is used; otherwise, AES-256 (SSE-S3) encryption
    is applied. This is a CIS AWS Benchmark Level 2 requirement.
    Default: true (strongly recommended).
  EOT
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = <<-EOT
    The ARN of the KMS key to use for server-side encryption. When provided,
    SSE-KMS encryption is used instead of SSE-S3 (AES-256). The KMS key must
    be in the same region as the bucket. Cross-account KMS keys are supported
    but require appropriate key policy configuration. Set to null to use
    Amazon S3 managed keys (SSE-S3).
    Default: null (uses AES-256 / SSE-S3).
  EOT
  type        = string
  default     = null
}

################################################################################
# Public Access Block
################################################################################

variable "block_public_access" {
  description = <<-EOT
    Enable all four S3 public access block settings. When true, the following
    are all set to true:
    - block_public_acls: Blocks new public ACLs and uploading public objects
    - ignore_public_acls: Ignores all public ACLs on the bucket and objects
    - block_public_policy: Blocks new public bucket policies
    - restrict_public_buckets: Restricts access to principals in the bucket owner's account
    This is a CIS AWS Benchmark Level 1 requirement.
    Default: true (strongly recommended for all buckets).
  EOT
  type        = bool
  default     = true
}

################################################################################
# Logging
################################################################################

variable "enable_logging" {
  description = <<-EOT
    Enable S3 server access logging. When enabled, detailed records of requests
    made to the bucket are delivered to a target bucket. Access logs are useful
    for security auditing, access analysis, and compliance. The target bucket
    must have appropriate ACL permissions.
    Default: false.
  EOT
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = <<-EOT
    The name of the S3 bucket where access logs will be delivered. Required when
    `enable_logging` is true. The target bucket must exist in the same region and
    have appropriate permissions (log-delivery-write ACL or bucket policy).
    Default: null.
  EOT
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = <<-EOT
    A prefix for the log object keys. All log object keys will begin with this
    prefix. Useful for organizing logs from multiple source buckets in a single
    target bucket. Example: "logs/my-bucket/".
    Default: null (logs are stored at the root of the target bucket).
  EOT
  type        = string
  default     = null
}

################################################################################
# Lifecycle Rules
################################################################################

variable "lifecycle_rules" {
  description = <<-EOT
    A list of lifecycle rule objects for managing object transitions and expiration.
    Each rule can define:
    - id:        (Required) Unique identifier for the rule.
    - enabled:   (Required) Whether the rule is active.
    - prefix:    (Optional) Object key prefix filter. Empty string applies to all objects.
    - transitions: (Optional) List of transition rules. Each contains:
      - days:          Number of days after creation to transition.
      - storage_class: Target storage class (INTELLIGENT_TIERING, STANDARD_IA,
                       ONEZONE_IA, GLACIER, GLACIER_IR, DEEP_ARCHIVE).
    - expiration: (Optional) Object expiration settings:
      - days: Number of days after creation to delete objects.
    - noncurrent_version_transitions: (Optional) Transitions for non-current versions:
      - days:          Days after becoming non-current to transition.
      - storage_class: Target storage class.
    - noncurrent_version_expiration: (Optional) Expiration for non-current versions:
      - days: Days after becoming non-current to permanently delete.
  EOT
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

################################################################################
# Replication
################################################################################

variable "enable_replication" {
  description = <<-EOT
    Enable cross-region or same-region replication for the S3 bucket. Replication
    requires versioning to be enabled on both source and destination buckets.
    An IAM role with appropriate permissions must be provided via `replication_role_arn`.
    Default: false.
  EOT
  type        = bool
  default     = false
}

variable "replication_role_arn" {
  description = <<-EOT
    The ARN of the IAM role that S3 assumes to replicate objects. The role must
    have permissions to read from the source bucket, replicate objects, and write
    to the destination bucket(s). Required when `enable_replication` is true.
    Default: null.
  EOT
  type        = string
  default     = null
}

variable "replication_rules" {
  description = <<-EOT
    A list of replication rule configurations. Each rule defines:
    - id:                  (Required) Unique identifier for the rule.
    - status:              (Required) "Enabled" or "Disabled".
    - priority:            (Optional) Priority of the rule. Higher number = higher priority.
    - prefix:              (Optional) Object key prefix filter.
    - destination_bucket:  (Required) ARN of the destination bucket.
    - destination_storage_class: (Optional) Storage class for replicated objects.
    - replicate_delete_markers:  (Optional) Whether to replicate delete markers.
  EOT
  type = list(object({
    id                         = string
    status                     = string
    priority                   = optional(number, 0)
    prefix                     = optional(string, "")
    destination_bucket         = string
    destination_storage_class  = optional(string, "STANDARD")
    replicate_delete_markers   = optional(bool, true)
  }))
  default = []
}

################################################################################
# Object Lock
################################################################################

variable "enable_object_lock" {
  description = <<-EOT
    Enable S3 Object Lock for the bucket. Object Lock provides WORM (Write Once
    Read Many) protection for objects. Once enabled on a bucket, Object Lock
    cannot be disabled. Requires versioning. Object Lock must be enabled at
    bucket creation time.
    Default: false.
  EOT
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = <<-EOT
    The default Object Lock retention mode for new objects placed in the bucket.
    Valid values:
    - GOVERNANCE: Users with specific IAM permissions can override lock settings.
    - COMPLIANCE: No user, including the root account, can override or delete locked objects.
    Required when `enable_object_lock` is true.
    Default: "GOVERNANCE".
  EOT
  type        = string
  default     = "GOVERNANCE"
}

variable "object_lock_days" {
  description = <<-EOT
    The default number of days that objects are locked after creation. This sets
    the default retention period for all new objects placed in the bucket. Objects
    can have individual lock settings that override this default. Must be a
    positive integer.
    Default: 30.
  EOT
  type        = number
  default     = 30
}

################################################################################
# CORS
################################################################################

variable "cors_rules" {
  description = <<-EOT
    A list of CORS (Cross-Origin Resource Sharing) rule objects. Each rule defines:
    - allowed_headers: (Optional) List of headers allowed in preflight requests.
    - allowed_methods: (Required) List of HTTP methods allowed (GET, PUT, POST, DELETE, HEAD).
    - allowed_origins: (Required) List of origins allowed to make requests.
    - expose_headers:  (Optional) List of headers exposed to the browser.
    - max_age_seconds: (Optional) Time in seconds the browser caches preflight response.
    Example use: enabling direct browser uploads to S3.
  EOT
  type = list(object({
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

################################################################################
# Static Website Hosting
################################################################################

variable "enable_website" {
  description = <<-EOT
    Enable static website hosting on the S3 bucket. When enabled, the bucket
    serves objects as a static website using the specified index and error
    documents. Note: website endpoints use HTTP only; use CloudFront for HTTPS.
    Default: false.
  EOT
  type        = bool
  default     = false
}

variable "index_document" {
  description = <<-EOT
    The name of the index document for the website. This is the page returned
    when requests are made to the root URL or any subfolder. Typically "index.html".
    Required when `enable_website` is true.
    Default: "index.html".
  EOT
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = <<-EOT
    The name of the error document for the website. This page is returned for
    4XX class errors. Typically "error.html".
    Default: "error.html".
  EOT
  type        = string
  default     = "error.html"
}

################################################################################
# Event Notifications
################################################################################

variable "event_notifications" {
  description = <<-EOT
    Configuration for S3 event notifications. Supports routing events to Lambda
    functions, SQS queues, and SNS topics. Each notification target specifies:
    - id:            (Required) Unique identifier for the notification.
    - arn:           (Required) ARN of the Lambda function, SQS queue, or SNS topic.
    - events:        (Required) List of S3 event types (e.g., "s3:ObjectCreated:*").
    - filter_prefix: (Optional) Object key prefix filter.
    - filter_suffix: (Optional) Object key suffix filter.
    Ensure the target resource has appropriate permissions to receive S3 notifications.
  EOT
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

################################################################################
# Access Points
################################################################################

variable "access_points" {
  description = <<-EOT
    A map of S3 Access Point configurations. Access Points simplify managing
    data access at scale for applications using shared datasets. Each access
    point can have its own permissions and network controls. Map key is the
    access point name. Each value contains:
    - name:   (Required) Name of the access point.
    - vpc_id: (Optional) VPC ID to restrict access to a specific VPC. When set,
              the access point is only accessible from within the specified VPC.
    - policy: (Optional) JSON access point policy document.
  EOT
  type = map(object({
    name   = string
    vpc_id = optional(string, null)
    policy = optional(string, null)
  }))
  default = {}
}

################################################################################
# Bucket Policy
################################################################################

variable "bucket_policy" {
  description = <<-EOT
    A valid JSON bucket policy document to attach to the bucket. This policy is
    merged with the TLS enforcement policy when `enforce_tls` is true. Use
    `aws_iam_policy_document` data source to generate the policy JSON for better
    readability and validation. Set to null for no custom policy.
    Default: null.
  EOT
  type        = string
  default     = null
}

variable "enforce_tls" {
  description = <<-EOT
    Enforce TLS (HTTPS) for all requests to the S3 bucket by attaching a bucket
    policy that denies any request made over plain HTTP. This is a CIS AWS
    Benchmark Level 2 recommendation and an AWS Security Hub best practice.
    Default: true (strongly recommended).
  EOT
  type        = bool
  default     = true
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = <<-EOT
    A map of tags to assign to all resources created by this module. Tags are
    key-value pairs that help with resource identification, cost allocation,
    access control, and automation. Common tags include Environment, Project,
    Owner, and CostCenter.
    Default: {} (no additional tags).
  EOT
  type        = map(string)
  default     = {}
}
