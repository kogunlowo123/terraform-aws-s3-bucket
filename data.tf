################################################################################
# Data Sources
################################################################################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

################################################################################
# TLS Enforcement Policy
################################################################################

data "aws_iam_policy_document" "tls_enforcement" {
  count = var.enforce_tls ? 1 : 0

  statement {
    sid       = "EnforceTLSRequestsOnly"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "EnforceTLSVersion"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

################################################################################
# Combined Policy (TLS + Custom)
################################################################################

data "aws_iam_policy_document" "custom" {
  count = var.enforce_tls && var.bucket_policy != null ? 1 : 0

  source_policy_documents = [var.bucket_policy]
}

data "aws_iam_policy_document" "combined" {
  count = var.enforce_tls && var.bucket_policy != null ? 1 : 0

  source_policy_documents = [
    data.aws_iam_policy_document.tls_enforcement[0].json,
    data.aws_iam_policy_document.custom[0].json,
  ]
}
