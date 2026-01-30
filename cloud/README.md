 IoT MVP - AWS Cloud Infrastructure

Complete Infrastructure as Code (IaC) for the IoT MVP cloud backend using Terraform and AWS services.

 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud (eu-west-1)                   │
│                                                              │
│  ┌──────────────┐        ┌─────────────────────────────┐   │
│  │  IoT Core    │───────>│  Amazon Timestream DB       │   │
│  │  (MQTT/TLS)  │        │  - 90-day hot storage       │   │
│  └──────────────┘        │  - 2-year warm storage      │   │
│         │                └─────────────────────────────┘   │
│         │                                                   │
│         │ IoT Rules Engine                                 │
│         ├────────────────────────────┐                     │
│         │                            │                     │
│         v                            v                     │
│  ┌──────────────┐           ┌──────────────┐             │
│  │   Lambda     │           │     SNS      │             │
│  │ Alert Handler│──────────>│   Alerts     │             │
│  └──────────────┘           └──────────────┘             │
│                                      │                     │
│                                      v                     │
│                              Email/SMS/Push                │
│                                                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │         API Gateway (REST + WebSocket)            │    │
│  │  - Cognito JWT authentication                     │    │
│  │  - Lambda authorizers (building_id claims)        │    │
│  └──────────────────────────────────────────────────┘    │
│         │                                                  │
│         v                                                  │
│  ┌─────────────────┐         ┌──────────────┐           │
│  │   Cognito       │         │     S3       │           │
│  │  User Pools     │         │ (Firmware)   │           │
│  └─────────────────┘         └──────────────┘           │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

 AWS Services Used

| Service | Purpose | Cost (20 devices) |
|---------|---------|-------------------|
| AWS IoT Core | MQTT broker, device registry | £0.96/year |
| Amazon Timestream | Time-series database (sensor data) | £1.44/year |
| AWS Lambda | Alert processing, API handlers | £0.20/year |
| Amazon SNS | Email/SMS notifications | £2.00/year |
| Amazon S3 | Firmware storage for OTA updates | £0.50/year |
| API Gateway | REST API for dashboard/mobile | £1.20/year |
| AWS Cognito | User authentication | Free (MAU <50,000) |
| CloudWatch Logs | Logging and monitoring | £0.50/year |
| DynamoDB (Terraform state) | Infrastructure state locking | £1.00/year |
| TOTAL | | £7.80/year |

 Prerequisites

 Software Requirements
- Terraform v1.6.0 or later
- AWS CLI v2.x
- Python 3.11+ (for Lambda development)
- jq (JSON processor)

 AWS Account Requirements
- AWS Account with admin access
- AWS CLI configured with credentials
- Sufficient service quotas for IoT Core, Timestream

 Setup Instructions

 1. Configure AWS CLI

```bash
 Configure AWS credentials
aws configure

 Verify access
aws sts get-caller-identity
```

 2. Create Terraform Backend (One-time)

```bash
 Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket iot-mvp-terraform-state \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

 Enable versioning
aws s3api put-bucket-versioning \
  --bucket iot-mvp-terraform-state \
  --versioning-configuration Status=Enabled

 Enable encryption
aws s3api put-bucket-encryption \
  --bucket iot-mvp-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

 Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name iot-mvp-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

 3. Deploy Infrastructure

```bash
cd cloud/terraform

 Initialize Terraform
terraform init

 Review planned changes
terraform plan -out=tfplan

 Apply infrastructure
terraform apply tfplan

 Save outputs
terraform output -json > outputs.json
```

 4. Create IoT Gateway Certificate

```bash
 Create certificate and private key
aws iot create-keys-and-certificate \
  --set-as-active \
  --certificate-pem-outfile gateway.crt \
  --public-key-outfile gateway_public.key \
  --private-key-outfile gateway.key

 Get certificate ARN
CERT_ARN=$(aws iot list-certificates --query 'certificates[0].certificateArn' --output text)

 Attach policy to certificate
aws iot attach-policy \
  --policy-name iot-mvp-gateway-policy-prod \
  --target $CERT_ARN

 Download Amazon Root CA
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -o AmazonRootCA1.pem

echo "Certificates created successfully!"
echo "Copy these files to Raspberry Pi gateway:"
echo "  - gateway.crt"
echo "  - gateway.key"
echo "  - AmazonRootCA1.pem"
```

 5. Configure Dashboard/Mobile App

```bash
 Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url)

 Get Cognito details
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_client_id)

 Get IoT Core endpoint
IOT_ENDPOINT=$(terraform output -raw iot_endpoint)

echo "API Gateway URL: $API_URL"
echo "Cognito User Pool ID: $USER_POOL_ID"
echo "Cognito Client ID: $CLIENT_ID"
echo "IoT Endpoint: $IOT_ENDPOINT"
```

 Lambda Functions

 Deploy Lambda Functions

```bash
cd cloud/lambda

 Package alert handler
zip -r alert_handler.zip alert_handler.py

 Update Lambda function
aws lambda update-function-code \
  --function-name iot-mvp-alert-handler-prod \
  --zip-file fileb://alert_handler.zip

 Test Lambda function
aws lambda invoke \
  --function-name iot-mvp-alert-handler-prod \
  --payload file://test_event.json \
  response.json

cat response.json
```

 Lambda Environment Variables

| Variable | Description |
|----------|-------------|
| `SNS_TOPIC_ARN` | SNS topic ARN for alerts (auto-configured) |
| `ENVIRONMENT` | Deployment environment (dev/staging/prod) |

 Timestream Queries

 Query Recent Telemetry
```sql
SELECT 
  device_id, 
  time, 
  measure_value::double AS co2_ppm,
  measure_value::double AS temperature_c
FROM "iot-mvp-sensor-data-prod"."telemetry"
WHERE time > ago(1h)
ORDER BY time DESC
LIMIT 100
```

 Query Average CO2 by Device (Last 24 Hours)
```sql
SELECT 
  device_id,
  AVG(CASE WHEN measure_name = 'co2_ppm' THEN measure_value::double END) AS avg_co2,
  AVG(CASE WHEN measure_name = 'temperature_c' THEN measure_value::double END) AS avg_temp
FROM "iot-mvp-sensor-data-prod"."telemetry"
WHERE time > ago(24h)
GROUP BY device_id
```

 Query Occupancy Trends
```sql
SELECT 
  BIN(time, 1h) AS hour_bucket,
  COUNT() AS events,
  SUM(CASE WHEN measure_value::boolean = true THEN 1 ELSE 0 END) AS occupied_count
FROM "iot-mvp-sensor-data-prod"."telemetry"
WHERE measure_name = 'occupancy' AND time > ago(7d)
GROUP BY BIN(time, 1h)
ORDER BY hour_bucket DESC
```

 Monitoring and Alerting

 CloudWatch Metrics

| Metric | Namespace | Description |
|--------|-----------|-------------|
| `PublishIn.Success` | AWS/IoT | Successful MQTT publishes |
| `RuleMessageThrottled` | AWS/IoT | Throttled rule actions |
| `SystemErrorRate` | AWS/Timestream | Write errors |
| `Invocations` | AWS/Lambda | Lambda invocation count |

 CloudWatch Alarms

```bash
 Create alarm for high error rate
aws cloudwatch put-metric-alarm \
  --alarm-name iot-mvp-iot-errors \
  --alarm-description "Alert on IoT Core errors" \
  --metric-name RuleMessageThrottled \
  --namespace AWS/IoT \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

 View Logs
```bash
 IoT Core error logs
aws logs tail /aws/iot/errors-prod --follow

 Lambda logs
aws logs tail /aws/lambda/iot-mvp-alert-handler-prod --follow
```

 Cost Optimization

 Current Costs (20 devices, 10-min sampling)

Monthly breakdown:
- IoT Core: 20 devices × 4,320 msgs/month × $0.00000125 = $0.11
- Timestream (Memory): 20 devices × 0.02 GB × $0.036/GB = $0.01
- Timestream (Magnetic): 20 devices × 0.5 GB × $0.003/GB = $0.03
- Lambda: 8,640 invocations × 100ms × $0.0000002/100ms = $0.02
- SNS: 50 notifications × $0.0004 = $0.02
- API Gateway: 10,000 requests × $0.000001 = $0.01
- S3: 0.1 GB × $0.023/GB = $0.002
- CloudWatch: $0.05

Total: ~$0.25/month = $3.00/year

 Optimization Strategies

1. Reserved Capacity (100+ devices):
   - Timestream Reserved Capacity: 20% savings
   - Lambda Provisioned Concurrency: 40% savings

2. Data Retention Tuning:
   - Reduce hot storage: 90 days → 30 days (-60%)
   - Reduce warm storage: 2 years → 1 year (-50%)

3. Sampling Rate Adjustment:
   - Increase interval: 10 min → 15 min (-33% messages)

4. Alert Deduplication:
   - Implement 5-minute cooldown (reduces SNS costs)

 Security Best Practices

 Certificate Management
- Rotate certificates annually
- Use AWS IoT Device Defender for audit
- Enable certificate revocation lists (CRL)

 IAM Policies
- Follow principle of least privilege
- Use IAM roles (not users) for services
- Enable CloudTrail for audit logging

 Network Security
- Enforce TLS 1.2 minimum
- Use AWS IoT device policies for fine-grained access
- Enable VPC endpoints for private connectivity

 Data Encryption
- All data encrypted in transit (TLS 1.2)
- All data encrypted at rest (AES-256)
- Use AWS KMS for key management

 Disaster Recovery

 Backup Strategy
- Terraform state: S3 versioning enabled
- Timestream data: Export to S3 via scheduled Lambda
- Certificates: Store securely in AWS Secrets Manager

 Recovery Procedures
```bash
 Restore infrastructure from Terraform state
terraform init
terraform plan
terraform apply

 Restore Timestream data from S3 backup
aws timestream-write write-records \
  --database-name iot-mvp-sensor-data-prod \
  --table-name telemetry \
  --records file://backup.json
```

 Troubleshooting

 Issue: IoT Core Connection Failures
```bash
 Check certificate status
aws iot describe-certificate --certificate-id <cert-id>

 Test MQTT connection
mosquitto_pub \
  --cafile AmazonRootCA1.pem \
  --cert gateway.crt \
  --key gateway.key \
  -h <iot-endpoint> \
  -p 8883 \
  -t test/topic \
  -m "test message"
```

 Issue: Timestream Write Errors
```bash
 Check CloudWatch Logs
aws logs filter-log-events \
  --log-group-name /aws/iot/errors-prod \
  --filter-pattern "Timestream"

 Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn <role-arn> \
  --action-names timestream:WriteRecords \
  --resource-arns <table-arn>
```

 Issue: High Latency
- Check CloudWatch metrics: `Latency` for API Gateway
- Review Lambda execution time: `Duration` metric
- Optimize Timestream queries: Add indexes, use time predicates

 Cleanup

```bash
 Destroy all infrastructure (WARNING: This deletes all data!)
terraform destroy

 Optionally remove backend resources
aws s3 rb s3://iot-mvp-terraform-state --force
aws dynamodb delete-table --table-name iot-mvp-terraform-locks
```

 References

- [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
- [Amazon Timestream Documentation](https://docs.aws.amazon.com/timestream/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [AWS Well-Architected Framework - IoT Lens](https://docs.aws.amazon.com/wellarchitected/latest/iot-lens/)

 Support

For issues or questions, contact: devops@example.com

 License

Proprietary - IoT MVP Team, January 2026
