# Advanced S3 Bucket Example

This example creates a production-grade S3 bucket setup with:

- Intelligent Tiering lifecycle rules for cost optimization
- Access logging to a dedicated log bucket
- Cross-region replication to us-west-2
- Non-current version lifecycle management
- IAM role for replication with least-privilege permissions

## Architecture

```
Primary Bucket (us-east-1) --replication--> Replica Bucket (us-west-2)
       |
       +--access-logs--> Log Bucket (us-east-1)
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Resources Created

| Resource | Description |
|----------|-------------|
| Primary Bucket | Main application data bucket |
| Replica Bucket | Cross-region replication destination |
| Log Bucket | Access log storage with lifecycle |
| IAM Role | Replication role with least-privilege policy |

## Cost Considerations

- Intelligent Tiering has a small monitoring fee per object
- Cross-region replication incurs data transfer charges
- Glacier storage significantly reduces per-GB costs for archived versions
