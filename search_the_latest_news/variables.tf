variable "allowed_ip" {
  description = "The IP address allowed to access the S3 bucket"
  type        = string
}

variable "brave_api_key" {
  description = "Brave Search API キー"
  type        = string
  sensitive   = true
}