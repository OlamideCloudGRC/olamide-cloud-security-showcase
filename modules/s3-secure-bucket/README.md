# Secure S3 Bucket Terraform Module

## Overview

This Terraform module creates an AWS S3 bucket with a **defense-in-depth security baseline** for cloud security, compliance, and automation workloads.

It implements **active denial** of non-compliant requests and maintains strict **separation of concerns**. It creates only bucket-level resources and excludes features that would create external dependencies.

---

## Design Philosophy: Separation of Concerns

This module is intentionally **focused and decoupled**. It creates only the S3 bucket and its direct security controls. Features that create relationships to other infrastructure are **excluded by design** and belong in the root module or integration modules.

| Feature | Included? | Why |
|---------|-----------|-----|
| Bucket + encryption + versioning + lifecycle | ✅ | Core bucket properties |
| Public access block + ownership controls | ✅ | Direct bucket security settings |
| Bucket policy (HTTPS + KMS enforcement) | ✅ | Attached directly to the bucket |
| Access logging | ❌ | Connects source bucket to log bucket (bidirectional coupling) |
| Replication | ❌ | Requires destination bucket ARN + IAM role |
| Event notifications | ❌ | Depends on external SQS/SNS/Lambda targets |
| Metrics + CloudWatch alarms | ❌ | Thresholds vary by workload; belongs in monitoring module |
| VPC endpoint restrictions | ❌ | Network-layer decision, not bucket property |

**The result:** This module can be used for source buckets, destination buckets, log buckets, or any other use case — without circular dependencies or tangled configuration.

---

## Threat Model

### In Scope (Mitigated by This Module)

| Threat | Mitigation | Control |
|--------|------------|---------|
| Accidental public exposure | Block public ACLs + bucket policies | `block_public_acls = true` |
| Unencrypted data at rest | Deny PutObject without `aws:kms` header | Bucket policy condition |
| Man-in-the-middle attack | Deny HTTP requests | `aws:SecureTransport = false` |
| Accidental object deletion or overwrite | Versioning keeps recoverable object versions | `aws_s3_bucket_versioning` |
| Long-term storage growth | Lifecycle rules transition or expire objects based on retention settings | `aws_s3_bucket_lifecycle_configuration` |
| Over-permissive ACLs | `BucketOwnerEnforced` ownership | Disables legacy ACLs |
| KMS key misconfiguration | Module requires key ARN; doesn't create keys | Separation of concerns |


### Out of Scope (Must Be Addressed Elsewhere)

| Threat | Where to Address |
|--------|------------------|
| Compromised AWS credentials | IAM roles + MFA + CloudTrail + GuardDuty |
| Data exfiltration by insider | S3 Access Logs (configured in root module) + CloudTrail Lake + SIEM |
| Cross-region disaster recovery | Replication configuration (root module) |
| Malicious KMS key deletion | KMS key policies + deletion window |
| Network-layer DDoS | AWS Shield (enabled by default for S3) |
| Slow detection of security events | EventBridge + SQS/Lambda (root module) |
| Insufficient monitoring | CloudWatch alarms + metrics (monitoring module) |
| Deletion protection beyond versioning | Object Lock, restricted delete permissions, or MFA Delete where operationally appropriate |
| Ransomware or compliance immutability | Object Lock, backup strategy, replication, and incident response controls |

### Risk Acceptance

Versioning improves recoverability from accidental deletion or overwrite, but it does not fully protect against a compromised identity that can permanently delete object versions. Compliance-critical buckets may require additional controls such as Object Lock, access logging, CloudTrail data events, replication, and restricted delete permissions.

---

## What This Module Creates

This module creates:

- `aws_s3_bucket`
- `aws_s3_bucket_public_access_block`
- `aws_s3_bucket_ownership_controls`
- `aws_s3_bucket_versioning`
- `aws_s3_bucket_server_side_encryption_configuration`
- `aws_s3_bucket_lifecycle_configuration`
- `aws_s3_bucket_policy`
- Outputs for bucket integration

---

## What This Module Does Not Create (Intentional)
| Resource | Why Excluded |
|----------|--------------|
| KMS keys	| Key policies are a separate security domain; may be shared across buckets |
| S3 access logging	| Creates bidirectional coupling between source and log buckets |
| Replication rules	| Requires destination bucket ARN + IAM role + potentially different region |
| Event notifications |	Depends on external SQS/SNS/Lambda resources |
| CloudWatch alarms |	Alerting thresholds vary by data sensitivity and workload |
| VPC endpoint policies |	Network-layer decision; belongs in networking module |
| Metrics configuration |	Monitoring strategy is workload-specific |

These exclusions are intentional design decisions, not omissions. They keep the module reusable, testable, and free of circular dependencies, allowing it to be used for source buckets, destination buckets, log buckets, or any other use case.

---

## Usage Example

```hcl
module "secure_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name              = var.bucket_name
  environment              = var.environment
  kms_key_arn              = aws_kms_key.bucket_encryption.arn
  tags                     = local.standard_tags

  enable_bucket_versioning = true
  enable_bucket_key        = true
  force_destroy            = false

  enable_lifecycle_rule    = true
  lifecycle_rule_id        = "standard-lifecycle-rule"
  lifecycle_prefix         = ""
  transition_days          = 30
  transition_storage_class = "STANDARD_IA"
  expiration_days          = 365
}
```

### Example: Trigger Bucket
```hcl
module "trigger_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name              = var.trigger_bucket_name
  environment              = var.environment
  kms_key_arn              = aws_kms_key.trigger_encryption.arn
  tags                     = local.standard_tags

  enable_bucket_versioning = true
  enable_bucket_key        = true
  force_destroy            = false

  enable_lifecycle_rule    = true
  lifecycle_rule_id        = "trigger-bucket-lifecycle"
  lifecycle_prefix         = ""
  transition_days          = 30
  transition_storage_class = "STANDARD_IA"
  expiration_days          = 365
}
```

### Example: Log Bucket
```hcl
module "log_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name              = var.log_bucket_name
  environment              = var.environment
  kms_key_arn              = aws_kms_key.log_encryption.arn
  tags                     = local.standard_tags

  enable_bucket_versioning = true
  enable_bucket_key        = true
  force_destroy            = false

  enable_lifecycle_rule    = true
  lifecycle_rule_id        = "log-bucket-lifecycle"
  lifecycle_prefix         = "logs/"
  transition_days          = 30
  transition_storage_class = "STANDARD_IA"
  expiration_days          = 365
}
```

### Example: Root-Level S3 Logging

S3 logging is configured outside this module because it connects a source bucket to a target bucket.

```hcl
resource "aws_s3_bucket_logging" "trigger_bucket_logging" {
  bucket = module.trigger_bucket.bucket_id

  target_bucket = module.log_bucket.bucket_id
  target_prefix = "logs/${module.trigger_bucket.bucket_name}/"
}
```
---

## Inputs

| Name                       | Description                                                        | Type          | Default                   | Required |
| -------------------------- | ------------------------------------------------------------------ | ------------- | ------------------------- | -------- |
| `bucket_name`              | Name of the S3 bucket.                                             | `string`      | n/a                       | yes      |
| `environment`              | Deployment environment such as dev, test, staging, or prod.        | `string`      | n/a                       | yes      |
| `kms_key_arn`              | KMS key ARN used for S3 server-side encryption.                    | `string`      | n/a                       | yes      |
| `tags`                     | Tags to apply to the bucket.                                       | `map(string)` | n/a                       | yes      |
| `enable_bucket_versioning` | Enables S3 bucket versioning.                                      | `bool`        | `true`                    | no       |
| `enable_bucket_key`        | Enables S3 Bucket Key for KMS cost optimization.                   | `bool`        | `true`                    | no       |
| `force_destroy`            | Allows Terraform to delete a non-empty bucket.                     | `bool`        | `false`                   | no       |
| `enable_lifecycle_rule`    | Creates the S3 lifecycle rule when enabled.                        | `bool`        | `true`                    | no       |
| `lifecycle_rule_id`        | ID of the lifecycle rule.                                          | `string`      | `standard-lifecycle-rule` | no       |
| `lifecycle_prefix`         | Object prefix used for lifecycle filtering.                        | `string`      | `""`                      | no       |
| `transition_days`          | Number of days before objects transition to another storage class. | `number`      | `30`                      | no       |
| `transition_storage_class` | Storage class objects transition to.                               | `string`      | `STANDARD_IA`             | no       |
| `expiration_days`          | Number of days before objects expire.                              | `number`      | `365`                     | no       |

---

## Outputs
| Name                 | Description                   |
| -------------------- | ----------------------------- |
| `bucket_id`          | ID of the S3 bucket.          |
| `bucket_name`        | Name of the S3 bucket.        |
| `bucket_arn`         | ARN of the S3 bucket.         |
| `bucket_domain_name` | Domain name of the S3 bucket. |


---

### Common Errors & Troubleshooting
|Error| Likely Cause | Solution |
|-----|--------------|----------|
| AccessDenied when uploading |	Missing x-amz-server-side-encryption: aws:kms header |	Add header or use AWS SDK with SSE-KMS |
| InvalidBucketPolicy |	KMS key policy missing S3 service principal	| Add "Service": "s3.amazonaws.com" to key policy |
| OperationAborted | Bucket name already exists globally | Add random suffix or use unique name |
| NoSuchBucket (logging)	| Target logging bucket doesn't exist	| Create log bucket before source bucket |
| KMS:NotFoundException	| KMS key ARN is incorrect or key is disabled	| Verify key ARN and key state |
| AccessDenied on force_destroy	| IAM lacks s3:DeleteObject and s3:DeleteBucket	| Add permissions for bucket cleanup |

---

## Operational Notes
- Keep `force_destroy` set to `false` for production, log, and compliance buckets.
- Use customer-managed KMS keys for sensitive or regulated data.
- Make sure the KMS key policy allows the required AWS services and IAM roles to use the key.
- Lifecycle rules are enabled by default to support retention and cost control.
- S3 logging should be configured in the root module because it depends on both a source bucket and a log bucket.
- Upload clients may need to explicitly set the `aws:kms` encryption header because the bucket policy denies non-KMS uploads.

---

### Portfolio Relevance

This module demonstrates the following security engineering competencies:

| Competency |	Evidence |
|------------|-----------|
| Defense in depth |	Multiple overlapping controls including encryption, bucket policy enforcement, versioning, lifecycle management, public access blocking and ownership controls |
| Secure by default	| Versioning enabled, HTTPS enforced, public access blocked, KMS required — no "opt-in" for critical controls |
| Active denial, not just defaults |	Bucket policy explicitly denies non-compliant requests (stronger than default encryption) |
| Separation of concerns	| Logging, replication, notifications, alarms, VPC policies are correctly excluded |
| Separation of security domains	| Bucket doesn't create its own KMS keys; requires them as input |
| Cost-aware security |	S3 Bucket Key enabled by default; lifecycle configurable per data class |
| Operational readiness	| force_destroy toggle prevents production accidents |
| Threat modeling |	Explicit in-scope/out-of-scope documentation |
| Troubleshooting expertise | Common error table based on real operational experience |
| Architectural judgment |	Clear rationale for what is excluded and why |

---

## Future Improvements

Potential future improvements include additional validation, testing, and optional compliance-focused features:

- Stronger S3 bucket name validation
- Lifecycle variable validation
- Optional Object Lock support for compliance evidence buckets
- Example folders for trigger bucket and log bucket use cases
- Automated validation with `terraform validate`, `tflint`, or Checkov
- A dedicated KMS module that passes its key ARN into this S3 module
