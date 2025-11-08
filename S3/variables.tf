variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "object_key" {
  description = "Key (path) for the S3 object"
  type        = string
}

variable "local_file_path" {
  description = "Local file path to upload"
  type        = string
}