variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックスに使用）"
  type        = string
  default     = "bedrock-search"
}

variable "bedrock_model_id" {
  description = "BedrockモデルID"
  type        = string
  default     = "global.anthropic.claude-sonnet-4-6"
}

# Secrets Manager に格納するシークレット値
# terraform apply 時に -var オプションまたは .tfvars ファイルで指定
variable "google_api_key" {
  description = "Google Custom Search APIキー"
  type        = string
  sensitive   = true
}

variable "google_cx" {
  description = "Google Custom Search エンジンID"
  type        = string
  sensitive   = true
}
