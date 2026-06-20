variable "allowed_ip" {
  description = "The IP address allowed to access the S3 bucket"
  type        = string
}

variable "brave_api_key" {
  description = "Brave Search API キー"
  type        = string
  sensitive   = true
}

variable "ses_sender_email" {
  description = "SES 送信元メールアドレス（AWS SES で検証済みのアドレス）"
  type        = string
}

variable "search_schedule" {
  description = "定期検索のスケジュール (EventBridge rate/cron 形式)"
  type        = string
  default     = "rate(1 day)"
}