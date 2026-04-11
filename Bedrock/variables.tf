# ===== AWS リソースのデプロイ設定 =====
# このファイルでは、インフラストラクチャ全体で使用する変数を定義しています

# AWS リージョンの設定
# デフォルトは日本リージョン(東京)に設定
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

# ===== S3 バケット設定 =====
# 静的なHTMLファイルをホストするS3バケット名
variable "s3_bucket_name" {
  description = "S3 bucket for static website"
  type        = string
}

variable "filepath_index_html" {
  description = "File path to the index.html file for the static website"
  type        = string
}

# ===== Lambda 関数設定 =====
# Bedrock APIを呼び出すLambda関数の名前
variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "filepath_lambda_py" {
  description = "File path to the Lambda deployment package (Python file)"
  type        = string
}

variable "filepath_lambda_zip" {
  description = "File path to the Lambda deployment package (ZIP file)"
  type        = string
}

# ===== API Gateway 設定 =====
# クライアントからのリクエストを受け付ける HTTP API の名前
variable "api_name" {
  description = "API Gateway name"
  type        = string
}

# ===== IAM ロール設定 =====
# Lambda関数が使用するIAMロール名
# このロールには Bedrock へのアクセス権限と CloudWatch ログへの書き込み権限が付与されます
variable "lambda_role_name" {
  description = "IAM role name for Lambda"
  type        = string
}

# ===== セキュリティ設定 =====
# S3バケットへのアクセスを許可するIPアドレスレンジ（CIDR表記）
variable "allowed_ip" {
  description = "Allowed IP address range for S3 bucket access (CIDR notation)"
  type        = string
}