# AWS Security & Compliance Automation Portfolio

![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![Python](https://img.shields.io/badge/Code-Python-blue?logo=python&logoColor=white)
![Security](https://img.shields.io/badge/Focus-Security-red?logo=datadog&logoColor=white)

## Certifications

![AWS Solutions Architect Associate](https://img.shields.io/badge/AWS_Solutions_Architect_Associate-232F3E?logo=amazonaws&logoColor=white)
![AWS SysOps Administrator Associate](https://img.shields.io/badge/AWS_SysOps_Administrator_Associate-232F3E?logo=amazonaws&logoColor=white)
![AWS Security Specialty](https://img.shields.io/badge/AWS_Security_Specialty-232F3E?logo=amazonaws&logoColor=white)

---

## Executive Summary
This repository demonstrates how cloud security and compliance requirements can be translated into practical AWS controls, Terraform-managed infrastructure, and security automation workflows.

It is designed to show how governance and risk requirements move from documentation into implementation through:

- secure Terraform deployment patterns
- AWS infrastructure with embedded security controls
- compliance-oriented monitoring and remediation workflows
- security documentation and testing evidence that explain design choices

The focus is not on building a generic cloud environment. The focus is on showing how cloud security engineering, compliance thinking, and automation can work together in a practical AWS portfolio.

---

## What This Portfolio Covers
### Cloud security engineering
- Secure AWS infrastructure patterns
- IAM role assumption for deployment workflows
- Encryption-aware design
- WAF protections for internet-facing traffic
- Logging, monitoring, and configuration governance

### Infrastructure as code
- Terraform-managed infrastructure
- Secure backend state handling
- Environment-aware variables and deployment patterns
- Repeatable provisioning for security-focused use cases

### Security automation
- Python and AWS Lambda for control validation and response workflows
- Event-driven compliance checking
- Security monitoring and remediation patterns

### Governance and compliance alignment
- Technical control mapping to frameworks such as:
  - NIST 800-53
  - PCI-DSS
  - HIPAA
  - CIS AWS Foundations

---

## What Is Included in This Repository

### Provisioned with Terraform
This portfolio includes Terraform code for AWS infrastructure and security-focused cloud components such as:

- Terraform backend configuration
- Provider configuration using assumed-role deployment patterns
- VPC and supporting network resources
- Application-facing infrastructure such as ALB and Auto Scaling
- ACM and Route 53 components
- Security groups
- WAF configuration
- AWS Config-related setup
- KMS monitoring-related infrastructure
- S3-focused compliance automation resources

### Implemented in code
The repository also includes Python-based Lambda functions that support cloud security automation use cases such as:

- S3 encryption compliance checking and remediation logic
- KMS rotation monitoring logic
- Incident response automation patterns for compromised compute scenarios

### Documented and demonstrated through supporting artifacts
The repository includes architecture, compliance, and testing materials that explain the design and show how the workflows were evaluated, including:

- architecture documentation
- compliance mapping
- risk and control thinking
- testing artifacts and screenshots
- workflow validation notes

---

## Scope Note

This is a portfolio repository, not a full enterprise landing zone.

Some capabilities are fully provisioned in Terraform.  
Some are implemented primarily through Lambda code.  
Some are demonstrated through architecture documentation and testing artifacts.

---

## Why This Portfolio Matters

Many cloud security problems are not caused by the absence of tools. They are caused by weak control implementation, inconsistent guardrails, poor visibility, and slow response.

This portfolio is meant to show a different approach:

- build controls into infrastructure where possible
- use automation to reduce manual security effort
- document control intent clearly
- connect implementation choices back to governance and risk expectations

The goal is to show practical security engineering judgment, not just cloud provisioning.


## Repository Structure

### `bootstrap/`
Secure bootstrap resources for Terraform deployments, including the foundations needed to support safer infrastructure provisioning patterns.

### `terraform/`
Terraform code for the AWS infrastructure and cloud security controls implemented in this portfolio.

### `lambda/`
Python-based automation used for compliance monitoring, control checks, and response workflows.

### `docs/`
Architecture, compliance, and supporting design documentation explaining how the portfolio is structured and why specific controls were chosen.

### `TESTING_REPORT/`
Artifacts that document workflow validation, simulations, screenshots, and supporting evidence for the security automation use cases.

---

## Reviewer Guide

### 5-minute review path
If you want a quick understanding of this portfolio, review in this order:

1. This README
2. `terraform/`
3. `lambda/`
4. `docs/ARCHITECTURE.md`
5. `TESTING_REPORT/`

### Technical deep-dive path
If you want to review implementation detail, go in this order:

1. `bootstrap/`
2. `terraform/`
3. `lambda/`
4. `docs/`
5. `TESTING_REPORT/`

---

## Key Technical Signals

This portfolio is meant to signal capability in the following areas:

- AWS security-focused infrastructure design
- Terraform for secure cloud provisioning
- IAM and least-privilege deployment thinking
- compliance-aware implementation
- event-driven automation
- practical cloud governance
- security documentation and evidence discipline

---

## Current Limitations

This repository is intentionally focused and does not claim to be a complete production platform.

Areas I would extend next include:

- stronger CI validation and IaC security scanning
- more reusable Terraform module structure
- cleaner environment layering
- tighter parameterization of environment-specific values
- more complete end-to-end provisioning for all documented response workflows
- expanded policy-as-code guardrails

---

## Closing

This project reflects how I think about cloud security engineering:

- controls should be practical
- automation should reduce risk, not add noise
- infrastructure should be secure by design
- documentation should make control intent clear
- governance requirements should translate into real implementation decisions

If you are reviewing this repository as a hiring manager, security leader, or technical peer, the goal is for you to see not just what was built, but how security thinking shaped the build.