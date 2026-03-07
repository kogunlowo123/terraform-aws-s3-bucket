# Basic S3 Bucket Example

This example creates a secure S3 bucket with the following features:

- Server-side encryption (AES-256)
- Versioning enabled
- All public access blocked
- TLS enforcement via bucket policy
- BucketOwnerEnforced ownership controls

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| None | All defaults are used | - |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
