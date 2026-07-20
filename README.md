# Serverless AWS FinOps Pipeline (IaC)

A production-ready Infrastructure as Code (IaC) framework built in Terraform to automate cloud cost anomaly detection, decoupling, and auditing under strict least-privilege security controls.

## 🏗️ Architecture & Data Flow

This pipeline operates entirely serverless to minimize operational costs while providing real-time infrastructure event logging:

1. **Ingestion Layer:** An Amazon S3 bucket (`mjp-cost-reports-bucket`) serves as the secure landing zone for automated daily AWS Cost Usage Reports (CUR).
2. **Decoupling & Event Mesh:** Bucket notifications trigger an Amazon SQS Queue, decoupling file ingestion from processing to handle high-volume spikes or retries without loss of data.
3. **Compute Layer:** An AWS Lambda execution function is triggered by SQS events, parsing cost anomalies using a custom runtime execution role.
4. **Data Layer:** Verified cost anomalies are indexed into an Amazon DynamoDB state table (`CostAnomaliesLog`) for operational auditing and tracking.

## 📊 Data Pipeline Architecture Diagram

```text
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  AWS Cost &  │ ──> │  Amazon S3   │ ──> │  AWS Lambda  │ ──> │  Amazon SQS  │
│ Usage Report │     │  Raw Ingest  │     │  (S3 Event)  │     │ Anomaly Queue│
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                                      │
                                                                      ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  CloudWatch  │ <── │  AWS Lambda  │ <── │   AWS Glue   │ <── │    Amazon    │
│ Metric Alarm │     │ (Threshold)  │     │ Data Catalog │     │    Athena    │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘

⚙️ Data Flow & Transformation Stages
Ingestion: Hourly AWS CUR manifests are delivered straight to a secured Amazon S3 storage bucket.

Event Trigger: S3 Object Created events drop metadata payloads directly into an automated processing lane.

Analytical Querying: AWS Lambda invokes Amazon Athena to parse partitioned SQL layers looking for unblended cost spikes.

Cataloging & Alerting: AWS Glue catalogs schema updates while metric anomalies are pushed to CloudWatch dashboards for operational visibility.

🛡️ Hardened Security Architecture
Least-Privilege IAM Roles: The processing Lambda function uses a strictly scoped execution policy (MJP-Lambda-FinOps-Execution-Role), blocking all standard administration actions and limiting access exclusively to the target S3 bucket and DynamoDB logs.

Server-Side Encryption: All data at rest within the S3 ingestion layer is continuously encrypted using managed KMS keys.

🛠️ Infrastructure Tooling Stack
Orchestration: AWS Lambda (Python runtime engine)

Data Lake Layer: Amazon S3 & AWS Glue Data Catalog

Query Compute Engine: Amazon Athena (Serverless Presto/Trino)

Alerting Protocol: Amazon SNS & CloudWatch Metrics

🚀 Deployment Instructions
To initialize and validate this infrastructure template locally:

PowerShell
# 1. Initialize the backend providers and lock modules
terraform init

# 2. Run a dry-run execution plan to verify compliance and resource mapping
terraform plan