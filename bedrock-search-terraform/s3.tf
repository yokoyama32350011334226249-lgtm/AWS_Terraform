# ───────────────────────────────────────────
# S3: フロントエンド静的ホスティング
# ───────────────────────────────────────────

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# ───────────────────────────────────────────
# index.html を S3 にアップロード
# API Gateway の URL をプレースホルダーに埋め込む
# ───────────────────────────────────────────

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content_type = "text/html; charset=utf-8"

  # API Gateway エンドポイントを HTML に埋め込む
  content = templatefile("${path.module}/index.html.tftpl", {
    api_endpoint = aws_apigatewayv2_stage.default.invoke_url
  })

  etag = md5(templatefile("${path.module}/index.html.tftpl", {
    api_endpoint = aws_apigatewayv2_stage.default.invoke_url
  }))

  tags = local.common_tags
}

# ───────────────────────────────────────────
# 現在のAWSアカウントID取得
# ───────────────────────────────────────────

data "aws_caller_identity" "current" {}
