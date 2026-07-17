# ==========================================
# 1. Terraform Initialization & Provider
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 2. S3 Storage & SQS Messaging (Decoupling)
# ==========================================
# S3 Bucket for storing simulated raw cost reports
resource "aws_s3_bucket" "billing_reports" {
  bucket        = "mjp-cost-reports-bucket"
  force_destroy = true # Safe for development teardown
}

# SQS Queue to decouple S3 upload events from the processing Lambda
resource "aws_sqs_queue" "billing_event_queue" {
  name                      = "billing-report-processing-queue"
  delay_seconds             = 0
  message_retention_seconds = 86400 # 1 day retention to control costs
  receive_wait_time_seconds = 10    # Long polling enabled to reduce API requests/costs
}

# ==========================================
# 3. DynamoDB State Storage (Free Tier)
# ==========================================
resource "aws_dynamodb_table" "cost_anomalies_db" {
  name         = "CostAnomaliesLog"
  billing_mode = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  hash_key = "ReportId"

  attribute {
    name = "ReportId"
    type = "S"
  }

  tags = {
    Owner       = "MJP-IT"
    Environment = "Production-Simulation"
  }
}

# ==========================================
# 4. Least-Privilege IAM Execution Policies
# ==========================================
# Trust relationship allowing Lambda to assume this role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_finops_role" {
  name               = "MJP-Lambda-FinOps-Execution-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Minimal policy: Only allow Read from S3, Read/Delete from SQS, and Write to DynamoDB
data "aws_iam_policy_document" "lambda_restricted_permissions" {
  # S3 Access: Read billing reports only from our specific bucket
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.billing_reports.arn}/*"]
  }

  # SQS Access: Read and clear messages from our queue
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.billing_event_queue.arn]
  }

  # DynamoDB Access: Put records into our anomalies database
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.cost_anomalies_db.arn]
  }

  # CloudWatch Access: Allow generating logs for troubleshooting
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_finops_policy" {
  name        = "MJP-Lambda-FinOps-Policy"
  description = "Strict least-privilege policy for FinOps processor"
  policy      = data.aws_iam_policy_document.lambda_restricted_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_finops_role.name
  policy_arn = aws_iam_policy.lambda_finops_policy.arn
}