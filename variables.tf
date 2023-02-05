variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-east-1"
}

variable "aws_bucket_name" {
  description = "Bucket name where lamda function will be uploaded"

  type    = string
  default = "aws-lambda-with-api-gateway"
}

variable "aws_credential_file_path" {
  description = "Path for AWS Credentails"

  type    = string
  default = "./credentials"
}