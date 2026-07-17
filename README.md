# Serverless AWS FinOps Pipeline (IaC)

A production-ready Infrastructure as Code (IaC) framework built in Terraform to automate cloud cost anomaly detection, decoupling, and auditing under strict least-privilege security controls.

## 🏗️ Architecture & Data Flow

This pipeline operates entirely serverless to minimize operational costs while providing real-time infrastructure event logging:

1. **Ingestion Layer:** An Amazon S3 bucket (`mjp-cost-reports-bucket`) serves as the secure landing zone for automated daily AWS Cost Usage Reports (CUR).
2. **Decoupling & Event Mesh:** Bucket notifications trigger an Amazon SQS Queue, decoupling file ingestion from processing to handle high-volume spikes or retries without loss of data.
3. **Compute Layer:** An AWS Lambda execution function is triggered by SQS events, parsing cost anomalies using a custom runtime execution role.
4. **Data Layer:** Verified cost anomalies are indexed into an Amazon DynamoDB state table (`CostAnomaliesLog`) for operational auditing and tracking.

## 🛡️ Hardened Security Architecture
- **Least-Privilege IAM Roles:** The processing Lambda function uses a strictly scoped execution policy (`MJP-Lambda-FinOps-Execution-Role`), blocking all standard administration actions and limiting access exclusively to the target S3 bucket and DynamoDB logs.
- **Server-Side Encryption:** All data at rest within the S3 ingestion layer is continuously encrypted using managed KMS keys.

## 🚀 Deployment Instructions

To initialize and validate this infrastructure template locally:

```powershell
# 1. Initialize the backend providers and lock modules
terraform init

# 2. Run a dry-run execution plan to verify compliance and resource mapping
terraform plan     