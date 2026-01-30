# IoT MVP - AWS Infrastructure as Code (Terraform)
# Smart Building Air Quality and Occupancy Monitoring System
# Author: IoT MVP Team
# Version: 1.0.0

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
  
  backend "s3" {
    bucket = "iot-mvp-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "eu-west-1"
    encrypt = true
    dynamodb_table = "iot-mvp-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "IoT-MVP"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CostCenter  = "Research"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "building_id" {
  description = "Building identifier"
  type        = string
  default     = "building-001"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################################################
# IoT Core - Device Management and Message Broker
#############################################################

# IoT Policy for Gateways
resource "aws_iot_policy" "gateway_policy" {
  name = "iot-mvp-gateway-policy-${var.environment}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/gateway-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/building/*/gateway/*/device/*/telemetry",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/building/*/gateway/*/status"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/building/*/gateway/*/ota/request"
        ]
      }
    ]
  })
}

# IoT Policy for API Users
resource "aws_iot_policy" "user_policy" {
  name = "iot-mvp-user-policy-${var.environment}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/user-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/building/${var.building_id}/*"
        ]
      }
    ]
  })
}

# IoT Topic Rule - Telemetry to Timestream
resource "aws_iot_topic_rule" "telemetry_to_timestream" {
  name        = "iot_mvp_telemetry_to_timestream_${var.environment}"
  description = "Route sensor telemetry to Amazon Timestream"
  enabled     = true
  sql         = "SELECT * FROM 'building/+/gateway/+/device/+/telemetry'"
  sql_version = "2016-03-23"
  
  timestream {
    database_name = aws_timestreamwrite_database.sensor_data.database_name
    table_name    = aws_timestreamwrite_table.telemetry.table_name
    role_arn      = aws_iam_role.iot_timestream_role.arn
    
    dimension {
      name  = "building_id"
      value = "${topic(2)}"
    }
    
    dimension {
      name  = "gateway_id"
      value = "${topic(4)}"
    }
    
    dimension {
      name  = "device_id"
      value = "${topic(6)}"
    }
    
    timestamp {
      value = "${timestamp()}"
      unit  = "MILLISECONDS"
    }
  }
  
  error_action {
    cloudwatch_logs {
      log_group_name = aws_cloudwatch_log_group.iot_errors.name
      role_arn       = aws_iam_role.iot_cloudwatch_role.arn
    }
  }
}

# IoT Topic Rule - High CO2 Alerts
resource "aws_iot_topic_rule" "co2_alert" {
  name        = "iot_mvp_co2_alert_${var.environment}"
  description = "Trigger alerts for high CO2 levels"
  enabled     = true
  sql         = "SELECT * FROM 'building/+/gateway/+/device/+/telemetry' WHERE sensor_data.co2_ppm > 1200"
  sql_version = "2016-03-23"
  
  lambda {
    function_arn = aws_lambda_function.alert_handler.arn
  }
}

# IoT Topic Rule - Low Battery Alerts
resource "aws_iot_topic_rule" "battery_alert" {
  name        = "iot_mvp_battery_alert_${var.environment}"
  description = "Trigger alerts for low battery"
  enabled     = true
  sql         = "SELECT * FROM 'building/+/gateway/+/device/+/telemetry' WHERE sensor_data.battery_mv < 2400"
  sql_version = "2016-03-23"
  
  lambda {
    function_arn = aws_lambda_function.alert_handler.arn
  }
}

#############################################################
# Amazon Timestream - Time-Series Database
#############################################################

resource "aws_timestreamwrite_database" "sensor_data" {
  database_name = "iot-mvp-sensor-data-${var.environment}"
  
  tags = {
    Name = "IoT MVP Sensor Data Database"
  }
}

resource "aws_timestreamwrite_table" "telemetry" {
  database_name = aws_timestreamwrite_database.sensor_data.database_name
  table_name    = "telemetry"
  
  retention_properties {
    magnetic_store_retention_period_in_days = 730  # 2 years warm storage
    memory_store_retention_period_in_hours  = 2160  # 90 days hot storage
  }
  
  magnetic_store_write_properties {
    enable_magnetic_store_writes = true
  }
  
  tags = {
    Name = "IoT MVP Telemetry Table"
  }
}

#############################################################
# Lambda Functions - Alert Processing
#############################################################

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "iot-mvp-lambda-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sns" {
  name = "lambda-sns-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.alerts.arn
        ]
      }
    ]
  })
}

# Lambda Function - Alert Handler
resource "aws_lambda_function" "alert_handler" {
  filename      = "lambda/alert_handler.zip"
  function_name = "iot-mvp-alert-handler-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "alert_handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      ENVIRONMENT   = var.environment
    }
  }
  
  tags = {
    Name = "IoT MVP Alert Handler"
  }
}

# Lambda Permission for IoT
resource "aws_lambda_permission" "iot_invoke" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_handler.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.co2_alert.arn
}

resource "aws_lambda_permission" "iot_invoke_battery" {
  statement_id  = "AllowExecutionFromIoTBattery"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_handler.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.battery_alert.arn
}

#############################################################
# SNS - Alerting and Notifications
#############################################################

resource "aws_sns_topic" "alerts" {
  name = "iot-mvp-alerts-${var.environment}"
  
  tags = {
    Name = "IoT MVP Alerts Topic"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "facilities@example.com"  # Replace with actual email
}

#############################################################
# API Gateway - REST API for Dashboard/Mobile
#############################################################

resource "aws_api_gateway_rest_api" "iot_api" {
  name        = "iot-mvp-api-${var.environment}"
  description = "IoT MVP REST API for dashboard and mobile applications"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource - /devices
resource "aws_api_gateway_resource" "devices" {
  rest_api_id = aws_api_gateway_rest_api.iot_api.id
  parent_id   = aws_api_gateway_rest_api.iot_api.root_resource_id
  path_part   = "devices"
}

# API Gateway Resource - /telemetry
resource "aws_api_gateway_resource" "telemetry" {
  rest_api_id = aws_api_gateway_rest_api.iot_api.id
  parent_id   = aws_api_gateway_rest_api.iot_api.root_resource_id
  path_part   = "telemetry"
}

# API Gateway Method - GET /devices
resource "aws_api_gateway_method" "get_devices" {
  rest_api_id   = aws_api_gateway_rest_api.iot_api.id
  resource_id   = aws_api_gateway_resource.devices.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

#############################################################
# Cognito - User Authentication
#############################################################

resource "aws_cognito_user_pool" "users" {
  name = "iot-mvp-users-${var.environment}"
  
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
  
  mfa_configuration = "OPTIONAL"
  
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
  }
  
  schema {
    name                = "building_id"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }
  
  tags = {
    Name = "IoT MVP User Pool"
  }
}

resource "aws_cognito_user_pool_client" "web_client" {
  name         = "iot-mvp-web-client"
  user_pool_id = aws_cognito_user_pool.users.id
  
  generate_secret = false
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.iot_api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.users.arn]
}

#############################################################
# CloudWatch - Logging and Monitoring
#############################################################

resource "aws_cloudwatch_log_group" "iot_errors" {
  name              = "/aws/iot/errors-${var.environment}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/iot-mvp-${var.environment}"
  retention_in_days = 30
}

#############################################################
# S3 - Firmware Storage for OTA Updates
#############################################################

resource "aws_s3_bucket" "firmware" {
  bucket = "iot-mvp-firmware-${var.environment}-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "IoT MVP Firmware Storage"
  }
}

resource "aws_s3_bucket_versioning" "firmware" {
  bucket = aws_s3_bucket.firmware.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firmware" {
  bucket = aws_s3_bucket.firmware.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#############################################################
# IAM Roles
#############################################################

# IoT to Timestream Role
resource "aws_iam_role" "iot_timestream_role" {
  name = "iot-mvp-iot-timestream-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_timestream_policy" {
  name = "timestream-write-policy"
  role = aws_iam_role.iot_timestream_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "timestream:WriteRecords"
        ]
        Resource = aws_timestreamwrite_table.telemetry.arn
      },
      {
        Effect = "Allow"
        Action = [
          "timestream:DescribeEndpoints"
        ]
        Resource = "*"
      }
    ]
  })
}

# IoT to CloudWatch Logs Role
resource "aws_iam_role" "iot_cloudwatch_role" {
  name = "iot-mvp-iot-cloudwatch-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_cloudwatch_policy" {
  name = "cloudwatch-logs-policy"
  role = aws_iam_role.iot_cloudwatch_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.iot_errors.arn}:*"
      }
    ]
  })
}

#############################################################
# Outputs
#############################################################

output "iot_endpoint" {
  description = "AWS IoT Core endpoint"
  value       = data.aws_iot_endpoint.endpoint.endpoint_address
}

output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = "${aws_api_gateway_rest_api.iot_api.execution_arn}/prod"
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.users.id
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.web_client.id
}

output "timestream_database" {
  description = "Timestream database name"
  value       = aws_timestreamwrite_database.sensor_data.database_name
}

output "timestream_table" {
  description = "Timestream table name"
  value       = aws_timestreamwrite_table.telemetry.table_name
}

data "aws_iot_endpoint" "endpoint" {
  endpoint_type = "iot:Data-ATS"
}
