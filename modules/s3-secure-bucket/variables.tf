variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}

variable "environment" {
  description = "Deployment environment such as Dev, Test, Staging, or Prod."
  type        = string

  validation {
    condition     = contains(["Dev", "Test", "Staging", "Prod"], var.environment)
    error_message = "Environment must be one of: Dev, Test, Staging, Prod."
  }
}

variable "tags" {
  description = "Tags to apply to the S3 bucket and related resources."
  type        = map(string)
}

variable "enable_bucket_versioning" {
  description = "Enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "enable_bucket_key" {
  description = "Enable S3 Bucket Key to reduce KMS request costs."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete a non-empty bucket. Keep false for production."
  type        = bool
  default     = false
}

variable "lifecycle_rule_id" {
  description = "ID/name of the S3 lifecycle rule."
  type        = string
  default     = "standard-lifecycle-rule"
}

variable "lifecycle_prefix" {
  description = "Object prefix used for the lifecycle rule filter."
  type        = string
  default     = ""
}

variable "transition_days" {
  description = "Number of days before objects transition to STANDARD_IA."
  type        = number
  default     = 30
}

variable "expiration_days" {
  description = "Number of days before objects expire."
  type        = number
  default     = 365
}

variable "enforce_kms_uploads" {
  description = "Deny object uploads that do not use aws:kms encryption."
  type        = bool
  default     = true
}

