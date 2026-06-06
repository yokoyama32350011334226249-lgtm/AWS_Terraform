variable "allowed_ip" {
  description = "The IP address allowed to access the S3 bucket"
  type        = string
}

variable "google_api_key" {
  description = "Google Custom Search API キー"
  type        = string
  sensitive   = true
}

variable "google_cse_id" {
  description = "Google Custom Search Engine ID"
  type        = string
  sensitive   = true
}