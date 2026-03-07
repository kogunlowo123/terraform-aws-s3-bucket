# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-07

### Added

- Initial release of the S3 bucket module
- S3 bucket with configurable naming (name or prefix)
- BucketOwnerEnforced ownership controls
- Versioning with optional MFA Delete support
- Server-side encryption (AES-256 or KMS with bucket key)
- Public access block (all four settings)
- TLS enforcement bucket policy (denies HTTP, requires TLS >= 1.2)
- Server access logging configuration
- Lifecycle rules with support for:
  - Intelligent Tiering transitions
  - Multi-stage storage class transitions
  - Object expiration
  - Non-current version transitions and expiration
- Cross-region and same-region replication
- Object Lock (WORM) with GOVERNANCE and COMPLIANCE modes
- CORS configuration
- Static website hosting
- Event notifications to Lambda functions, SQS queues, and SNS topics
- S3 Access Points with optional VPC restriction
- Custom bucket policy with automatic TLS policy merging
- Basic, advanced, and complete usage examples
- Comprehensive documentation with CIS benchmark alignment

[1.0.0]: https://github.com/kogunlowo123/terraform-aws-s3-bucket/releases/tag/v1.0.0
