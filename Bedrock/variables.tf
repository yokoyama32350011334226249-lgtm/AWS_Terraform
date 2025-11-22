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

# ===== Lambda 関数設定 =====
# Bedrock APIを呼び出すLambda関数の名前
variable "lambda_function_name" {
  description = "Lambda function name"
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
