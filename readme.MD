# AWS Platform API

A production-grade AWS infrastructure platform built entirely with Terraform, deploying a FastAPI application on ECS Fargate with full CI/CD, monitoring, and security scanning.

This project demonstrates end-to-end cloud infrastructure skills — from networking and container orchestration to automated deployments and observability — built as a portfolio project while transitioning into a DevOps career.

## Architecture

```
                         GitHub Push
                              │
                    ┌─────────▼──────────┐
                    │   GitHub Actions    │
                    │   (OIDC → AWS)      │
                    └─────────┬──────────┘
                              │
┌─────────────────────────────▼──────────────────────────────┐
│                     VPC (10.0.0.0/16)                      │
│                                                            │
│   Public Subnets (Multi-AZ)       Private Subnets (Multi-AZ)│
│  ┌──────────────────┐           ┌──────────────────────┐   │
│  │  ALB (port 80)   │──:8000──▶│  ECS Fargate         │   │
│  │                  │           │  (FastAPI container)  │   │
│  │  NAT Instance    │           │                      │   │
│  │  (t3.micro)      │           │  ──:5432──▶ RDS      │   │
│  └──────────────────┘           │            PostgreSQL │   │
│         ▲                       │  ──▶ SQS Queue       │   │
│         │                       │  ──▶ Secrets Manager  │   │
│    Internet Gateway              └──────────────────────┘   │
│                                                            │
│   CloudWatch Alarms ──▶ SNS ──▶ Email Alerts              │
└────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure as Code | Terraform 1.14.5 |
| Cloud Provider | AWS (eu-west-1) |
| Compute | ECS Fargate |
| Application | FastAPI (Python) |
| Container Registry | Amazon ECR |
| Database | RDS PostgreSQL 15 |
| Messaging | Amazon SQS |
| Secrets | AWS Secrets Manager |
| Load Balancer | Application Load Balancer |
| CI/CD | GitHub Actions with OIDC |
| Monitoring | CloudWatch Alarms + SNS |
| Security Scanning | checkov, tflint |

## Project Phases

### Phase 1 — Remote State

S3 backend for Terraform state with `use_lockfile = true` (Terraform 1.10+ replacement for the deprecated DynamoDB state locking). The state bucket is created via a separate `bootstrap/` Terraform configuration with versioning enabled, AES-256 server-side encryption, and all public access blocked. The bootstrap config uses local state and is the only component not managed by the remote backend.

### Phase 2 — Networking

Multi-AZ VPC with public and private subnets, Internet Gateway, and a NAT instance (t3.micro) instead of a NAT Gateway. Route tables direct public subnet traffic to the IGW and private subnet traffic through the NAT instance. Subnets are created dynamically using `for_each` with `cidrsubnet()` for programmatic CIDR allocation.

### Phase 3 — Containerisation

Multi-stage Dockerfile for the FastAPI application. ECR repository managed by Terraform with vulnerability scanning on push, lifecycle policies to limit untagged image retention, and `prevent_destroy` to protect against accidental deletion.

### Phase 4 — Compute (ECS Fargate + ALB)

ECS Fargate service running in private subnets, fronted by a public-facing ALB. Two separate IAM roles enforce least privilege: an execution role (used by the ECS agent to pull images and write logs) and a task role (used by the application at runtime to access SQS and Secrets Manager). Security group chaining ensures each layer only accepts traffic from the layer directly in front of it.

### Phase 5 — Database & Messaging

RDS PostgreSQL in private subnets with credentials generated via `random_password` and stored in Secrets Manager (never hardcoded). SQS queue with long polling for efficient message consumption. The FastAPI health check verifies database connectivity via boto3 at runtime.

### Phase 6 — CI/CD

GitHub Actions with OIDC authentication — no stored AWS credentials. A single workflow file uses `dorny/paths-filter` to detect which files changed and runs up to three jobs: change detection, Terraform apply (only when `Infra/**` changes), and Docker build/deploy (only when `app/**` changes). The `needs` dependency ensures deployment waits for infrastructure changes to complete.

### Phase 7 — Monitoring

Five CloudWatch alarms covering ECS CPU utilisation, ECS memory utilisation, ALB 5XX error rate, ALB response time, and ECS running task count. All alarms notify via an SNS topic that sends email alerts. The running task count alarm uses `treat_missing_data = "breaching"` — if metrics stop arriving entirely, it means the service is down, so silence itself triggers the alarm.

### Phase 8 — Security & Documentation

tflint with the AWS plugin for Terraform linting. checkov for static security analysis against CIS benchmarks. All findings reviewed, with fixes applied where appropriate and conscious trade-offs documented below.

## Architectural Decisions

These decisions were made deliberately and can each be explained with trade-offs:

**NAT Instance over NAT Gateway** — A t3.micro NAT instance costs roughly $3.50/month versus $32+/month for a NAT Gateway. The trade-off is no automatic failover, which is acceptable for a non-production workload. Savings of approximately 90%.

**OIDC over stored AWS credentials** — GitHub Actions authenticates via OIDC federation, generating short-lived temporary credentials per workflow run. No long-lived access keys are stored in GitHub Secrets, eliminating credential rotation burden and reducing blast radius if compromised.

**use_lockfile over DynamoDB** — Terraform 1.10+ introduced native S3 state locking via `use_lockfile = true`, replacing the need for a separate DynamoDB table. One fewer resource to manage with identical functionality.

**Separate execution and task IAM roles** — The ECS execution role handles infrastructure concerns (image pulling, log writing) while the task role handles application concerns (SQS, Secrets Manager). This follows least privilege — the agent doesn't get app permissions and the app doesn't get infrastructure permissions.

**Security group chaining** — Each layer's security group only allows inbound traffic from the security group of the layer in front of it (ALB → ECS → RDS). Even if an attacker knows the private IP of an ECS task, they cannot reach it without coming through the ALB.

**random_password for database credentials** — Database passwords are generated by Terraform's `random_password` resource and stored in Secrets Manager. Credentials are never hardcoded in code, variables, or tfvars files.

**prevent_destroy on critical resources** — ECR repository, OIDC provider, GitHub Actions IAM role, SNS topic, and SNS subscription all have `prevent_destroy = true`. This allows targeted destruction of expensive compute resources between sessions while preserving resources that are costly to recreate (confirmed subscriptions, OIDC trust relationships, container images).

**treat_missing_data = "breaching" on task count alarm** — Most alarms use `"notBreaching"` (no data means no problem). The running task count alarm deliberately uses `"breaching"` because if CloudWatch stops receiving this metric, the service is likely completely down — silence is the emergency, not the absence of one.

## Security Scanning Results

### tflint

All issues resolved. Every module includes `required_version` and `required_providers` constraints to ensure compatibility is explicit.

### checkov — Findings Fixed

| Check | Description | Fix Applied |
|---|---|---|
| CKV_AWS_226 | RDS auto minor version upgrade | `auto_minor_version_upgrade = true` |
| CKV_AWS_79 | EC2 IMDSv2 enforcement | `metadata_options` with `http_tokens = "required"` |
| CKV_AWS_135 | EC2 EBS optimisation | `ebs_optimized = true` |
| CKV_AWS_23 | Security group rule descriptions | Added `description` to all ingress/egress rules |
| CKV2_AWS_60 | RDS copy tags to snapshots | `copy_tags_to_snapshot = true` |
| CKV_AWS_131 | ALB drops invalid HTTP headers | `drop_invalid_header_fields = true` |

### checkov — Conscious Trade-offs (Skipped with Justification)

| Check | Description | Reason for Skipping |
|---|---|---|
| CKV_AWS_157 | RDS Multi-AZ | Doubles cost. Single-AZ is acceptable for a non-production dev environment. |
| CKV_AWS_293 | RDS deletion protection | Infrastructure is deliberately destroyed between sessions to manage costs. Deletion protection would block this workflow. |
| CKV_AWS_129 | RDS logging enabled | Adds storage cost and complexity. CloudWatch alarms already cover operational monitoring. |
| CKV2_AWS_30 | RDS query logging | Same as above — not required for a non-production workload. |
| CKV_AWS_353 | RDS Performance Insights | Additional monitoring cost. CloudWatch CPU/memory alarms provide sufficient visibility. |
| CKV_AWS_118 | RDS Enhanced Monitoring | Requires an additional IAM role and adds cost beyond the free tier. |
| CKV_AWS_161 | RDS IAM authentication | Secrets Manager already provides secure credential management. IAM auth adds complexity without meaningful security improvement for this use case. |
| CKV_AWS_126 | EC2 detailed monitoring | Extra cost for 1-minute metrics versus free 5-minute metrics. Not necessary for a NAT instance. |
| CKV2_AWS_41 | IAM role on EC2 instance | The NAT instance forwards packets only — it makes no AWS API calls and does not need a role. |
| CKV_AWS_8 | EC2 EBS encryption | NAT instance stores no sensitive data. Minimal risk for a packet-forwarding instance. |
| CKV2_AWS_11 | VPC flow logging | Adds cost. Useful for production audit trails but not required for a dev environment. |
| CKV2_AWS_12 | Default SG restricts all traffic | The default security group is not used by any resource. Low risk. |
| CKV2_AWS_57 | Secrets Manager auto rotation | Requires a Lambda function for rotation logic. Adds cost and complexity for a dev project. |
| CKV_AWS_27 | SQS encryption | Requires KMS key management. Acceptable trade-off for a non-production queue. |
| CKV_AWS_26 | SNS encryption | Same — KMS cost and management overhead. |
| CKV_AWS_136 | ECR KMS encryption | Same — default encryption is applied; custom KMS adds cost. |
| CKV_AWS_149 | Secrets Manager KMS CMK | Default encryption is applied; custom KMS adds cost with no practical benefit here. |
| CKV_AWS_158 | CloudWatch log group KMS | Same pattern — default encryption, custom KMS adds unnecessary cost. |
| CKV_AWS_338 | CloudWatch log retention 1 year | 7-day retention is sufficient for a dev project. Longer retention increases storage cost. |
| CKV_AWS_51 | ECR immutable tags | Mutable tags are intentional — allows overwriting `latest` on each push, which is standard in dev CI/CD workflows. |
| CKV_AWS_2 | ALB HTTPS protocol | HTTPS requires a custom domain and ACM certificate. No domain is configured for this project. |
| CKV_AWS_103 | ALB TLS 1.2 | Same — TLS requires HTTPS listener which requires a domain and certificate. |
| CKV_AWS_378 | Load balancer HTTP protocol | Same — internal ALB-to-ECS traffic uses HTTP. HTTPS would require end-to-end TLS setup. |
| CKV2_AWS_20 | ALB HTTP to HTTPS redirect | No HTTPS listener exists to redirect to. Requires a domain. |
| CKV2_AWS_28 | WAF on ALB | WAF adds cost. Appropriate for production but not for a dev learning project. |
| CKV_AWS_260 | ALB ingress from 0.0.0.0/0 on port 80 | This is a public-facing ALB — accepting HTTP traffic from the internet is by design. |
| CKV_AWS_382 | Security group egress 0.0.0.0/0 | Outbound internet access is required: ECS pulls images, NAT forwards traffic, RDS downloads updates. |
| CKV2_AWS_5 | Security groups not attached | False positive — checkov cannot trace cross-module security group references. All SGs are attached to ALB, ECS, and RDS in separate modules. |
| CKV_AWS_274 | AdministratorAccess on IAM role | Used on the GitHub Actions role for simplicity during development. Production would use least-privilege scoped policies. |
| CKV_AWS_150 | ALB deletion protection | Infrastructure is destroyed between sessions to manage costs. |
| CKV_AWS_91 | ALB access logging | Requires an S3 bucket for log storage. Additional cost for a dev project. |

## Cost Management

The project operates within a ~$30/month budget. Infrastructure is destroyed at the end of each working session using targeted destroy:

```bash
terraform destroy \
  -target=module.compute \
  -target=module.networking \
  -target=module.security \
  -target=module.database \
  -var-file="env-variables/dev.tfvars"
```

Resources that persist between sessions (protected by `prevent_destroy`):
- S3 state bucket (bootstrap, never touched by Terraform)
- ECR repository (container images)
- OIDC provider and GitHub Actions IAM role (CI/CD authentication)
- SNS topic and subscription (confirmed email subscription)

Estimated cost when running: ~$1.15/day.

## Project Structure

```
aws-platform-api/
├── bootstrap/
│   ├── main.tf                  # S3 state bucket with versioning, encryption, public access block
│   ├── variables.tf             # Bootstrap variables (project name, region)
│   └── outputs.tf               # Outputs bucket name and region
├── Infra/
│   ├── main.tf                  # Root module — wires all modules together
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values (ALB DNS, VPC ID, etc.)
│   ├── versions.tf              # Provider config, backend, OIDC resources
│   ├── env-variables/
│   │   └── dev.tfvars           # Environment-specific values
│   └── modules/
│       ├── Networking/          # VPC, subnets, IGW, NAT instance, route tables
│       ├── Security/            # Security groups (ALB, ECS, RDS)
│       ├── Compute/             # ECS cluster, task definition, ALB, IAM roles
│       ├── ECR/                 # Container registry
│       ├── Database/            # RDS, SQS, Secrets Manager
│       └── Observability/       # CloudWatch alarms, SNS topic
├── app/
│   ├── main.py                  # FastAPI application
│   ├── requirements.txt         # Python dependencies
│   └── Dockerfile               # Multi-stage container build
└── .github/
    └── workflows/
        └── pipeline.yml         # CI/CD workflow
```

## Prerequisites

- Terraform >= 1.10.0
- AWS CLI configured with appropriate credentials
- Docker Desktop
- Git

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DedicatedToCloud08/aws-platform-api.git
   ```

2. **Create the S3 state bucket** (one-time setup):
   ```bash
   cd aws-platform-api/bootstrap
   terraform init
   terraform apply
   ```
   This creates a versioned, encrypted S3 bucket with public access blocked. Note the `state_bucket_name` from the output — you'll need it in the next step. The bootstrap state is stored locally (this is the only component with local state).

3. **Update backend configuration** in `Infra/versions.tf` with the bucket name from step 2.

4. **Update `Infra/env-variables/dev.tfvars`** with your values.

5. **Initialise and apply the infrastructure:**
   ```bash
   cd ../Infra
   terraform init
   terraform plan -var-file="env-variables/dev.tfvars"
   terraform apply -var-file="env-variables/dev.tfvars"
   ```

6. **Access the application** via the ALB DNS name from the Terraform output.

## Author

Built by Prathamesh
- project demonstrating production-grade AWS infrastructure skills with Terraform, Docker, and GitHub Actions CI/CD.
