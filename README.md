# ETL Lambda DuckDB - POC

A Proof of Concept (POC) demonstrating the use of AWS Lambda with DuckDB as an alternative to traditional Spark-based data pipelines.

## Overview

This project implements a serverless ETL pipeline using AWS Lambda and DuckDB to process data files stored in S3. It showcases how lightweight, cost-effective serverless functions can replace heavier Spark infrastructure for certain data processing workloads.

## Architecture

The solution follows a lakehouse architecture pattern with three distinct data zones:

```
S3 Raw Bucket → Lambda (DuckDB) → S3 Silver/Gold Buckets
```

### Key Components

- **AWS Lambda**: Serverless compute running containerized DuckDB processing
- **DuckDB**: Embedded analytical database for data transformation
- **Amazon S3**: Three-tier lakehouse storage (raw, silver, gold)
- **Amazon ECR**: Container registry for Lambda Docker images
- **Amazon CloudWatch**: Logging and monitoring

### Data Flow

1. Data files land in the `raw` S3 bucket
2. S3 event notification triggers the Lambda function
3. Lambda processes data using DuckDB
4. Transformed data is written to `silver` or `gold` buckets

## Infrastructure

The infrastructure is defined using Terraform and consists of the following components:

### S3 Buckets (s3.tf:2-14)

Three S3 buckets implementing a lakehouse pattern:
- **raw-{account_id}**: Landing zone for raw ingested data
- **silver-{account_id}**: Cleaned and validated data
- **gold-{account_id}**: Business-ready aggregated data

Each bucket includes:
- Private ACL for security
- Server-side encryption (AES256)
- S3 event notifications (raw bucket triggers Lambda)

### Lambda Function (lambda.tf:1-11)

- **Function Name**: `duckdb_ingestion` (configurable)
- **Package Type**: Container image from ECR
- **Trigger**: S3 ObjectCreated events on raw bucket
- **Runtime**: Python 3.12 with DuckDB
- **Handler**: `main.lambda_handler`

### Container Registry (ecr.tf:1-40)

- **ECR Repository**: `lambda_duckdb`
- **Automated Build**: Terraform triggers Docker build and push
- **Rebuild Triggers**: Changes to Dockerfile, main.py, or requirements.txt
- **Security**: Image scanning enabled on push

### IAM Permissions (iam.tf:1-79)

Lambda execution role with permissions for:
- S3 read/write access to buckets
- CloudWatch Logs for monitoring
- EC2 network interfaces (VPC if needed)

### Application Code

**Dependencies** (requirements.txt:3-22):
- `boto3`: AWS SDK for Python
- `duckdb`: Embedded analytical database
- Supporting libraries (botocore, s3transfer, etc.)

**Lambda Handler** (main.py:9-25):
- Extracts S3 bucket and key from event
- Initializes DuckDB connection
- Configures S3 access via httpfs extension
- Uses AWS credential chain for authentication

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker installed and running
- AWS account with permissions to create:
  - Lambda functions
  - S3 buckets
  - ECR repositories
  - IAM roles and policies

## Configuration

### Variables (variables.tf:1-7)

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region for resource deployment |
| `lambda_name` | `duckdb_ingestion` | Name of the Lambda function |

## Deployment

1. Navigate to the infrastructure directory:
```bash
cd infra
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the planned changes:
```bash
terraform plan
```

4. Deploy the infrastructure:
```bash
terraform apply
```

The deployment process will:
- Create S3 buckets for raw, silver, and gold zones
- Set up ECR repository
- Build and push Docker image to ECR
- Deploy Lambda function with S3 trigger
- Configure IAM roles and permissions

## Usage

Once deployed, the pipeline activates automatically:

1. Upload a data file to the raw bucket:
```bash
aws s3 cp data.csv s3://raw-{account_id}/
```

2. Lambda function is triggered automatically
3. View logs in CloudWatch:
```bash
aws logs tail /aws/lambda/duckdb_ingestion --follow
```

## Cost Optimization

This architecture offers several cost advantages over Spark:

- **No Idle Resources**: Lambda charges only for execution time
- **No Cluster Management**: Eliminates EMR/Glue/Databricks costs
- **Efficient Processing**: DuckDB's columnar engine is highly optimized
- **Scalability**: Automatic scaling without pre-provisioning

## Limitations

Consider these limitations when using Lambda + DuckDB:

- **Execution Time**: 15-minute maximum Lambda timeout
- **Memory**: Up to 10GB Lambda memory limit
- **Storage**: 10GB ephemeral storage in /tmp
- **Best For**: Small to medium datasets (<1-2GB)

## Technology Comparison: DuckDB vs Spark

| Aspect | Lambda + DuckDB | Spark |
|--------|-----------------|-------|
| Setup Time | Seconds | Minutes |
| Cost Model | Pay-per-execution | Pay-per-cluster-hour |
| Cluster Management | None | Required |
| Data Size | Small-Medium (<2GB) | Any size |
| Processing Speed | Fast for small data | Fast for large data |

## Project Structure

```
.
├── infra/
│   ├── app/
│   │   ├── Dockerfile          # Lambda container definition
│   │   ├── main.py             # Lambda handler code
│   │   ├── requirements.txt    # Python dependencies
│   │   └── pyproject.toml      # Python project metadata
│   ├── main.tf                 # Terraform provider config
│   ├── variables.tf            # Input variables
│   ├── data.tf                 # Data sources
│   ├── s3.tf                   # S3 bucket resources
│   ├── lambda.tf               # Lambda function
│   ├── ecr.tf                  # Container registry
│   └── iam.tf                  # IAM roles and policies
├── .gitignore
└── README.md
```

## Cleanup

To destroy all created resources:

```bash
cd infra
terraform destroy
```

**Note**: Ensure S3 buckets are empty before destroying, or set `force_delete = true`.

## Future Enhancements

Potential improvements for this POC:

- [ ] Implement actual data transformation logic in Lambda
- [ ] Add Lambda environment variables for configuration
- [ ] Implement DLQ (Dead Letter Queue) for failed executions
- [ ] Add VPC configuration for private networking
- [ ] Implement CloudWatch alarms for monitoring
- [ ] Add Lambda layers for shared dependencies
- [ ] Implement Step Functions for complex workflows
- [ ] Add data quality checks and validation
- [ ] Implement incremental processing patterns

## License

This is a POC project for evaluation purposes.
