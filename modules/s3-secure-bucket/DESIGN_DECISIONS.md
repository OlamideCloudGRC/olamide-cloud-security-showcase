
# Design Decisions: Secure S3 Bucket Module

## Overview

This document captures the architectural reasoning behind this module's scope, boundaries, trade-offs and rejected alternatives. 

It complements the README:
- `README.md` explains how to use the module.
- `DESIGN_DECISIONS.md` explains why the module is designed this way.

**Status:** Living document. Updated as patterns evolve.

---

## Core Principle: Separation of Concerns

**Decision:** This module creates only the S3 bucket and its directly attached security controls. Features that create relationships to other infrastructure are excluded.

**Why:**

| Feature | Location | Reasoning |
|---------|----------|-----------|
| Bucket + encryption + versioning | Module | Core bucket properties |
| KMS keys | Root/KMS module | Key policy is separate security domain; keys may be shared across buckets |
| Access logging | Root module | Creates bidirectional coupling between source and log buckets |
| Replication | Root module | Requires destination bucket ARN + IAM role + potentially different region |
| Event notifications | Root module | Depends on external SQS/SNS/Lambda resources |
| CloudWatch alarms | Monitoring module | Alerting thresholds vary by workload and data sensitivity |
| VPC endpoint policies | Networking module | Network-layer decision, not bucket property |

**Trade-off:** Users must write more root module code to integrate these features. 

**Benefit:** No circular dependencies, independent lifecycles, and the same module works for source buckets, destination buckets, log buckets, and any other use case.

**Alternative considered:** A monolithic module with 20+ conditional flags. **Rejected because:** It creates hidden dependencies, makes testing harder, and couples unrelated concerns.

---

## Security Control Decisions

### Active Denial vs. Default Encryption

**Decision:** Use bucket policy to deny non-KMS uploads and non-HTTPS requests, not just configure default encryption.

```hcl
# This module does this (active denial)
condition {
  test     = "StringNotEquals"
  variable = "s3:x-amz-server-side-encryption"
  values   = ["aws:kms"]
}

# Not just this (default only)
server_side_encryption_configuration { ... }
```

**Why**: 
Default bucket encryption helps ensure objects are encrypted at rest, but it does not prove that clients explicitly requested the expected `aws:kms` encryption mode. The bucket policy adds active enforcement by denying uploads that omit the encryption header or use an encryption type other than `aws:kms`.

**Trade-off**: Clients MUST explicitly set the `x-amz-server-side-encryption: aws:kms` header. 

### KMS Key as Required Input (Not Created Here)
**Decision**: Module requires `var.kms_key_arn` but does not create the KMS key.

**Why**: 
- Key policies are a separate security domain with different audit requirements. A single KMS key may encrypt multiple buckets.

- Key deletion, rotation, and alias management are separate concerns

- Terraform state for KMS keys often needs additional protection (e.g., Terraform Cloud sensitive variables)

**Trade-off**: Users must create KMS keys separately. **Benefit**: Clear separation of duties. S3 team doesn't need KMS admin privileges.

**Alternative considered**: Optional key creation with `create_kms_key = true`. **Rejected because:** It creates a false sense of security isolation. The module can't manage key policies appropriately across all use cases.


### MFA Delete Not Included

**Decision:** MFA Delete is not implemented in this module.

**Why:**

MFA Delete requires root-account MFA workflows and does not fit cleanly into standard Terraform automation. 
This module uses versioning and `force_destroy = false` as baseline protection, while stronger delete protection should be handled through Object Lock, restricted delete permissions, or backup/replication controls.

**Trade-off:** This module does not provide MFA-based delete protection. For compliance-critical buckets, consider Object Lock, restricted delete permissions, CloudTrail data events, access logging, and backup or replication controls.

### Object Lock Not Included
**Decision:** Object Lock is not included.

**Why:**

- Object Lock adds significant complexity: once enabled, it cannot be disabled

- Compliance mode means no one (including root) can delete objects until retention expires

- Storage costs increase significantly (no lifecycle transitions during retention period)

**Trade-off:** This module does not provide immutable retention by default. For compliance evidence buckets or ransomware-resistant storage, Object Lock can be added later as an optional control with carefully selected retention mode and retention period.

**Alternative considered:** Add `enable_object_lock = true`. **Rejected for now because:** Object Lock affects bucket lifecycle, deletion behavior, retention cost, and compliance operations. It should be added only when the use case requires immutable retention.


### BucketOwnerEnforced (Not BucketOwnerPreferred or ObjectWriter)
**Decision:** Use object_ownership = "BucketOwnerEnforced".

**Why:**

- Disables all ACLs entirely

- Prevents object uploads from setting ownership or ACLs

- Access control becomes purely IAM + bucket policy (modern S3 security model)

**Trade-off:** Cannot grant cross-account access via object ACLs. **Benefit:** Eliminates entire class of ACL-related misconfigurations.

**Alternative considered:** BucketOwnerPreferred (preserves ACLs but grants ownership to bucket owner). **Rejected because:** ACLs remain an attack surface.

## Operational Decisions
### Lifecycle Rule: Single Rule with Optional Prefix
**Decision:** Support exactly one lifecycle rule with an optional prefix filter.

**Why:** This module serves 80% of use cases (log rotation, temp file cleanup, standard retention). Complex multi-rule lifecycles indicate a specialized workload that deserves its own module.

**Trade-off:** Users with complex retention policies (e.g., different prefixes → different transition schedules) need to extend or fork. **Benefit:** Keeps module simple and testable for common cases.

**Alternative considered:** Accept a list of lifecycle rule objects. **Rejected because:** That's a different module. Complex lifecycle management is a separate concern with its own validation requirements.

### force_destroy = false by default (Production Safe)
**Decision:** Default force_destroy = false and document that production buckets must keep it false.

**Why:** Setting force_destroy = true allows Terraform to delete a bucket containing data. This is not safe for production, audit, or log buckets.

**Trade-off:** Developers testing locally must explicitly opt into force_destroy = true. **Benefit:** Prevents the most common Terraform data-loss scenario.

### Versioning Enabled by Default
**Decision:** enable_bucket_versioning = true by default.

**Why:** Versioning is a baseline recovery control for accidental deletion, overwrites, and some unintended changes. The cost (storage for multiple versions) is acceptable for most workloads.

**Trade-off:** High-churn buckets (e.g., temporary staging) may accumulate storage costs. **Mitigation:** Document cost implications and provide override for dev/test.

## Excluded Features
### Access Logging
**Why excluded:** Logging creates a relationship between THIS bucket and a log bucket. If logging is built into the generic bucket module, the module has to know about another bucket. That creates coupling and can lead to awkward dependencies, especially when the same module is used for both source buckets and log buckets.

**Root module pattern:**

```hcl
module "source" { source = "./s3-module" }
module "logs"  { source = "./s3-module" }

resource "aws_s3_bucket_logging" "this" {
  bucket        = module.source.bucket_id
  target_bucket = module.logs.bucket_id
}
```
### Cross-Region Replication
**Why excluded:** Replication requires:

- Destination bucket ARN (potentially in different AWS provider alias)

- IAM role with specific trust policy

- Decision on delete marker replication

- Potential destination KMS key

Each of these is a root-level decision that shouldn't be hidden inside a module flag.

### Event Notifications
**Why excluded:** Notifications couple this bucket to specific SQS queues, SNS topics, or Lambda functions. Those targets have their own deployment lifecycles, permissions, and regional constraints.

### CloudWatch Alarms / Metrics
**Why excluded:** Alarming thresholds are workload-dependent. A bucket holding critical financial data needs different alarms than one holding ephemeral build logs.

### VPC Endpoint Restrictions
**Why excluded:** VPC endpoint policies are network architecture decisions. Restricting a bucket to specific VPCs or endpoints should be configured at the network layer or via a dedicated policy attachment module.

### Object Lock
**Why excluded:** Object Lock is useful for immutable retention, but it changes deletion behavior, retention operations, and compliance handling. It should be enabled only for buckets that require WORM-style protection, such as compliance evidence or audit log archives.

### MFA Delete
**Why excluded:** MFA Delete is not implemented because it does not fit cleanly into standard Terraform automation. It requires root-account MFA workflows and can break CI/CD, Lambda, and other automated workflows that cannot provide MFA tokens during deletion or versioning changes.

For this module, versioning and `force_destroy = false` provide baseline deletion protection. For compliance-critical buckets, stronger delete protection should be handled through Object Lock, restricted delete permissions, CloudTrail data events, access logging, backup, or replication controls.

### Addressing Common Review Comments
| Reviewer Comment | Response |
|---|---|
| Why no access logging? | Logging creates coupling between a source bucket and a log bucket, so it belongs in the root module. |
| Why no replication? | Replication requires a destination bucket, IAM role, KMS permissions, and DR design decisions. |
| Why no MFA Delete by default? | MFA Delete is not Terraform-friendly and can break automation. |
| Is this a complete security solution? | This is a secure bucket baseline that fits into a layered architecture. |
| Why only one lifecycle rule? | Complex lifecycle policies usually signal a specialized workload or separate module. |
| Why no Object Lock? | Object Lock is useful for compliance and immutability, but it changes retention and deletion behavior. It should be added only for buckets that require immutable retention. |


### Testing Strategy
This module is designed to be testable in isolation:

```hcl
# test/fixtures/basic/main.tf
module "test_bucket" {
  source = "../../../"
  
  bucket_name = "test-bucket-${random_id.suffix.hex}"
  environment = "test"
  kms_key_arn = aws_kms_key.test.arn
  tags        = { Test = "true" }
  
  force_destroy = true  # Safe for test cleanup
}
```
**What we test:**

- Bucket policy denies non-KMS uploads (using awscli with/without header)

- Bucket policy denies HTTP requests

- Versioning is enabled

- Public access block settings are enforced

**What we don't test here:**

- Logging delivery

- Replication behavior

- Event notification delivery



