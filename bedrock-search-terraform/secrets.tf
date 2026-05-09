# ───────────────────────────────────────────
# Secrets Manager
# ───────────────────────────────────────────

resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "/${var.project_name}/api-keys"
  description             = "Google Custom Search API キーと検索エンジンID"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id

  secret_string = jsonencode({
    GOOGLE_API_KEY = var.google_api_key
    GOOGLE_CX      = var.google_cx
  })
}
