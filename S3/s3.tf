resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ローカルファイルをS3にアップロード
resource "aws_s3_object" "upload_example" {
  bucket = aws_s3_bucket.example.id
  key    = var.object_key          # S3上でのファイルパス（例: "docs/readme.txt"）
  source = var.local_file_path     # ローカルのファイルパス（例: "./files/readme.txt"）

  etag = filemd5(var.local_file_path)

  content_type = "text/plain"      # MIMEタイプ（任意）
  acl          = "private"         # アクセス制御
}