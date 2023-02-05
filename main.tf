terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}


provider "aws" {
  region = var.aws_region
  shared_credentials_files = [var.aws_credential_file_path]
  profile = "testing"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.aws_bucket_name
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_sampleapp" {
  type = "zip"

  source_dir  = "${path.module}/sampleapp"
  output_path = "${path.module}/sampleapp.zip"
}

resource "aws_s3_object" "lambda_sampleapp" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "sampleapp.zip"
  source = data.archive_file.lambda_sampleapp.output_path

  etag = filemd5(data.archive_file.lambda_sampleapp.output_path)
}


// lambda function
resource "aws_lambda_function" "sampleapp" {
  function_name = "SampleApplication"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_sampleapp.key

  runtime = "nodejs14.x"
  handler = "sampleapp.handler"

  source_code_hash = data.archive_file.lambda_sampleapp.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "sampleapp" {
  name = "/aws/lambda/${aws_lambda_function.sampleapp.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
