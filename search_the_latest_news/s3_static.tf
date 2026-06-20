# ===== S3 バケット（静的サイトホスティング） =====
resource "aws_s3_bucket" "static_site" {
  bucket = "news-search-static-site"
}

resource "aws_s3_bucket_ownership_controls" "static_site_ownership" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "static_site_public_access" {
  bucket                  = aws_s3_bucket.static_site.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "static_site_website" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.allowed_ip
          }
        }
      }
    ]
  })
}

# ===== index.html のアップロード（templatefile で API URL を埋め込む） =====
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_site.id
  key    = "index.html"
  content = templatefile("${path.module}/website/index.html.tmp", {
    api_endpoint       = aws_apigatewayv2_api.chat_api.api_endpoint
    items_api_endpoint = aws_apigatewayv2_api.items_api.api_endpoint
  })
  content_type = "text/html"
  acl          = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.static_site_ownership,
    aws_s3_bucket_public_access_block.static_site_public_access,
    aws_s3_bucket_policy.static_site_policy,
    aws_s3_bucket_website_configuration.static_site_website
  ]
}
