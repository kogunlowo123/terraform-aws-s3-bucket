# Complete S3 Bucket Example

This example demonstrates all features of the S3 bucket module in a single deployment.

## Features Demonstrated

- **KMS Encryption**: Customer-managed KMS key with automatic key rotation
- **Versioning**: Enabled for data protection and recovery
- **Public Access Block**: All four settings enabled
- **Access Logging**: Server access logs delivered to a dedicated log bucket
- **Lifecycle Rules**: Intelligent Tiering, multi-stage archive, and temp cleanup
- **CORS**: Cross-origin access for web applications
- **Event Notifications**: SNS for object creation, SQS for object deletion
- **Access Points**: VPC-restricted access point for network isolation
- **Bucket Policy**: Custom policy merged with TLS enforcement
- **TLS Enforcement**: Denies non-HTTPS and TLS < 1.2 requests

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Architecture

```
                    +----> SNS Topic (object created)
                    |
Complete Bucket ----+----> SQS Queue (object deleted)
    |               |
    |               +----> Access Point (VPC restricted)
    |
    +--logs--> Log Bucket (with lifecycle)
```

## Important Notes

- The KMS key has a 7-day deletion window for safety
- Access point is VPC-restricted and only accessible from within the specified VPC
- Intelligent Tiering applies to all objects; document-specific archival is layered on top
- Temporary files under `temp/` are automatically deleted after 7 days
- Non-current versions of documents are archived and expire after 90 days
