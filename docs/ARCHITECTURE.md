# Architecture Overview

## Purpose

This document explains the architecture of the AWS Cloud Security & Compliance Automation Portfolio.

The purpose of the architecture is to show how cloud security controls, infrastructure components, and automation workflows fit together in a practical AWS design.

This is not intended to represent a complete enterprise landing zone.  
It is intended to show how security requirements can be translated into infrastructure patterns, monitoring workflows, and response-oriented automation.

---

## High-Level Architecture Goals

The architecture is designed around a small number of security-focused objectives:

- provision AWS infrastructure using Terraform with safer deployment patterns
- embed security controls into the infrastructure where practical
- support automation for selected monitoring and remediation use cases
- maintain a clear separation between infrastructure, automation logic, and supporting evidence
- reflect governance and compliance thinking through technical design choices

---

## Architectural Layers

The portfolio is easiest to understand when viewed in layers.

### 1. Deployment and provisioning layer
This layer shows how Terraform deployments are secured. It includes the use of a protected remote backend, state locking, and IAM role assumption to support more controlled and auditable infrastructure changes.

Key goals:
- controlled Terraform execution
- secure backend state management
- separation of duties through IAM role assumption
- repeatable provisioning patterns

Primary repository areas:
- `bootstrap/`
- `terraform/`

---

### 2. Infrastructure and control layer
This layer contains the AWS resources and security-oriented configuration patterns that form the main environment.

Representative components include:
- VPC and networking
- security groups
- ALB and Auto Scaling resources
- ACM and Route 53 configuration
- WAF protections for public application traffic
- AWS Config-related setup
- S3 resources supporting compliance workflows
- KMS monitoring-related infrastructure

Primary repository area:
- `terraform/`

---

### 3. Automation layer
This layer contains Lambda-based logic for selected cloud security workflows.

Representative use cases include:
- S3 encryption compliance checking and remediation logic
- KMS key rotation monitoring logic
- compromised EC2 response patterns

Primary repository area:
- `lambda/`

---

### 4. Documentation and evidence layer
This layer explains the design, control intent, testing approach, and risk reasoning behind the portfolio.

Representative materials include:
- architecture explanation
- compliance mapping
- threat and risk documentation
- testing artifacts and screenshots

Primary repository areas:
- `docs/`
- `TESTING_REPORT/`

---

## Core Architectural Concepts

### Secure Terraform deployment pattern
The architecture uses a Terraform-centered provisioning model designed to reflect better security discipline than direct ad hoc deployment. This includes secure state handling and IAM-aware deployment patterns.

The purpose is to show that infrastructure security starts with how infrastructure is managed, not only with what resources are created.

---

### Infrastructure with embedded security controls
The portfolio is structured to demonstrate that security controls should be part of the environment design, not an afterthought added later.

Examples include:
- WAF for public-facing application protection
- security group rules for controlled access patterns
- configuration governance support
- encryption-oriented design choices
- logging and evidence-aware setup

---

### Event-driven security automation
Selected workflows in the portfolio use Lambda and AWS event-driven services to model how security checks and responses can be automated.

The point is not to automate everything.  
The point is to automate targeted, high-value workflows where consistency, speed, and repeatability matter.

Examples include:
- S3 encryption validation and remediation logic
- KMS key rotation monitoring
- response-oriented handling for compromised compute scenarios

---

### Separation of implementation and evidence

A key design principle in this portfolio is transparency.

Not every capability in this repository is represented in the same way. Some controls are provisioned directly in Terraform. Some workflows are implemented primarily in Python and AWS Lambda. Others are supported through architecture documentation, testing artifacts, and validation evidence.

This distinction is intentional. It helps the repository be reviewed accurately by showing what is fully provisioned, what is implemented in code, and what is demonstrated through supporting evidence, without presenting every workflow as a fully production-complete deployment.


## Representative Component Relationships

At a high level, the architecture can be understood as follows:

1. Terraform provisions the core AWS infrastructure and control-supporting resources.
2. IAM and backend design support safer infrastructure deployment patterns.
3. Lambda functions implement selected monitoring and remediation logic.
4. Supporting services such as S3, KMS, AWS Config, EventBridge, and WAF help enforce or support security objectives.
5. Documentation and testing artifacts provide the reasoning and evidence behind the workflows.

---

## Security Design Intent

This portfolio is built around a focused set of security principles that shape both the implementation and the way the repository is documented.

### Least privilege
Infrastructure deployment and administrative access should follow more controlled patterns than broad standing permissions. This portfolio reflects that approach through IAM-aware deployment design, role assumption, and scoped access decisions intended to reduce unnecessary privilege.

### Secure-by-design infrastructure
Security controls are treated as part of the environment design rather than optional hardening added later. This portfolio includes examples such as WAF protections, configuration governance support, encryption-aware design, and access restrictions to show that infrastructure security should be built into the architecture itself.

### Defense in depth
The portfolio uses layered controls rather than relying on a single safeguard. For example, the S3 encryption workflow combines a preventive bucket policy with Lambda-based detection and remediation logic so that a single control failure does not leave the environment unprotected.

### Traceability
The repository is structured so a reviewer can connect security objectives to implementation and supporting evidence. Infrastructure code, automation logic, documentation, compliance mapping, and testing artifacts are included to make security decisions easier to follow and evaluate.

### Focused automation
Automation is applied where it improves consistency, reduces manual effort, or strengthens response workflows. In this portfolio, automation is used for selected monitoring, compliance, and remediation-oriented use cases rather than as broad, undifferentiated automation. automation.

---

## Architectural Limitations

This portfolio is intentionally scoped. It is not designed to cover every cloud security domain.

Current limitations include:
- it is not a full multi-account enterprise landing zone
- it does not claim full production readiness for every documented workflow
- some workflows are represented through code and evidence rather than complete end-to-end deployment in Terraform
- environment modularity and CI validation can be extended further

These limitations are part of the current scope, not hidden gaps.

---

## Closing

This portfolio is designed to show that cloud security engineering is not just about provisioning resources. It is about making deliberate design choices around access, controls, automation, and evidence.

The architecture reflects that goal by showing how security requirements were carried through the implementation, not added after the fact.
