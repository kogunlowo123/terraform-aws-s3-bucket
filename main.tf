################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  bucket_prefix = var.bucket_prefix
  force_destroy = var.force_destroy

  object_lock_enabled = var.enable_object_lock

  tags = local.common_tags
}

################################################################################
# Ownership Controls
################################################################################

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

################################################################################
# Versioning
################################################################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

################################################################################
# Server-Side Encryption
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }

    bucket_key_enabled = var.kms_key_arn != null ? true : false
  }
}

################################################################################
# Public Access Block
################################################################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

################################################################################
# Logging
################################################################################

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

################################################################################
# Lifecycle Configuration
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          days = expiration.value.days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions

        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
}

################################################################################
# Replication Configuration
################################################################################

resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0

  bucket = aws_s3_bucket.this.id
  role   = var.replication_role_arn

  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.replication_rules

    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority

      filter {
        prefix = rule.value.prefix
      }

      destination {
        bucket        = rule.value.destination_bucket
        storage_class = rule.value.destination_storage_class
      }

      delete_marker_replication {
        status = rule.value.replicate_delete_markers ? "Enabled" : "Disabled"
      }
    }
  }
}

################################################################################
# Object Lock Configuration
################################################################################

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.enable_object_lock ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.object_lock_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

################################################################################
# CORS Configuration
################################################################################

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

################################################################################
# Website Configuration
################################################################################

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.enable_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

################################################################################
# Event Notifications
################################################################################

resource "aws_s3_bucket_notification" "this" {
  count = local.has_notifications ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = var.event_notifications.lambda_functions

    content {
      id                  = lambda_function.value.id
      lambda_function_arn = lambda_function.value.arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = var.event_notifications.sqs_queues

    content {
      id            = queue.value.id
      queue_arn     = queue.value.arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = var.event_notifications.sns_topics

    content {
      id            = topic.value.id
      topic_arn     = topic.value.arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}

################################################################################
# Access Points
################################################################################

resource "aws_s3_access_point" "this" {
  for_each = var.access_points

  bucket = aws_s3_bucket.this.id
  name   = each.value.name

  dynamic "vpc_configuration" {
    for_each = each.value.vpc_id != null ? [each.value.vpc_id] : []

    content {
      vpc_id = vpc_configuration.value
    }
  }

  policy = each.value.policy
}

################################################################################
# Bucket Policy
################################################################################

resource "aws_s3_bucket_policy" "this" {
  count = local.attach_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = local.bucket_policy

  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_ownership_controls.this,
  ]
}
