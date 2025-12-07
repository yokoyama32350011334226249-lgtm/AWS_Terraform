# --- 変数定義ファイル ---

variable "aws_region" {
  type        = string
  description = "AWSリージョン（例: ap-northeast-1）"
}

variable "kendra_index_name" {
  type        = string
  description = "作成するKendraインデックスの名称"
}

# variable "kendra_role_arn" {
#   type        = string
#   description = "Kendraインデックス用 IAM Role ARN"
# }

# variable "kendra_datasource_role_arn" {
#   type        = string
#   description = "Kendra Webcrawler データソース用 IAM Role ARN"
# }

variable "seed_url" {
  type        = string
  description = "Webcrawler が最初にアクセスする Seed URL"
}