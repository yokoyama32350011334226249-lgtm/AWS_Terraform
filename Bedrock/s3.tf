# ===== S3 バケットの設定 =====
# このファイルでは、静的ウェブサイトをホストするためのS3バケットの構成を定義しています

# ===== S3 バケット（ウェブサイトホスティング用） =====
# 目的: 静的な HTML/CSS/JavaScript ファイルを公開インターネットから アクセス可能にホストする
# 機能:
#   - ウェブサイトホスティング機能を有効化
#   - インデックスドキュメントとエラードキュメントを index.html に設定
#   - 公開読み取りアクセスを許可
resource "aws_s3_bucket" "static_site" {
  bucket = var.s3_bucket_name
}

# ============================
# Object Ownership（ACL 無効化）
# ----------------------------
# ・S3 バケット内のオブジェクト所有権を「バケット所有者強制（BucketOwnerEnforced）」にする設定
# ・ACL を完全に無効化し、オブジェクト所有権の衝突を避ける（推奨設定）
# ・これにより、すべてのオブジェクトは自動でバケット所有者のものとして扱われる
# ============================
resource "aws_s3_bucket_ownership_controls" "ownership" {
  # 所有権コントロールを設定する対象バケット
  bucket = aws_s3_bucket.static_site.id

  rule {
    # BucketOwnerEnforced を設定
    # → ACL を完全に無効化し、バケット所有者を常にオブジェクト所有者とする
    object_ownership = "BucketOwnerEnforced"
  }
}

# ============================
# Public Access Block（ACL 使用不可）
# ----------------------------
# ・S3 バケットが意図せずパブリックアクセスを持つことを防ぐ設定
# ・ACL はすでに無効化しているため block_public_acls と ignore_public_acls を true にする
# ・ポリシーベースでアクセス許可したい場合は block_public_policy を false に設定（ここは要件による）
# ============================
resource "aws_s3_bucket_public_access_block" "public_access" {
  # Public Access Block を設定する対象バケット
  bucket = aws_s3_bucket.static_site.id

  # ACL を利用したパブリックアクセスをブロックする
  block_public_acls = true

  # 既存の ACL がパブリックであっても無視してブロックする
  ignore_public_acls = true

  # バケットポリシーによるパブリックアクセスをブロックする
  block_public_policy = true

  # 新規作成されるオブジェクトに対してもパブリックアクセスを禁止する
  restrict_public_buckets = true
}

# ============================
# Website Hosting（新形式）
# ============================
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_site.id

  # index と error ドキュメントの設定
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

# ===== S3 バケットポリシー（アクセス権限設定） =====
# 目的: 誰でも S3 バケット内のオブジェクトを GetObject（読み込み）できるようにする
# 効果: インターネットから静的ファイルにアクセス可能になる
resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id
  
  # IAM ポリシードキュメント（JSON形式）
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # アクション許可
        Effect = "Allow"
        # 対象: すべてのユーザー（認証不要）
        Principal = "*"
        # 許可アクション: S3オブジェクトの読み込み
        Action = "s3:GetObject"
        # 対象リソース: バケット内のすべてのオブジェクト
        Resource = "${aws_s3_bucket.static_site.arn}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.allowed_ip
          }
        }
      }
    ]
  })
}

# ===== S3 オブジェクトアップロード（ウェブサイトのトップページ） =====
# 目的: HTML ファイルを S3 バケットに自動的にアップロード
# 機能: Terraform の apply 時に index.html がバケットにアップロードされる
resource "aws_s3_object" "index_html" {
  # アップロード先のバケット
  bucket = aws_s3_bucket.static_site.id
  # バケット内でのオブジェクトのキー（パス）
  key = "index.html"
  # templatefile で API URL を埋め込む
  content = templatefile("${path.module}/website/index.html.tpl", {
    api_endpoint = aws_apigatewayv2_api.api.api_endpoint
  })
  # ファイルの MIME タイプ（HTML ファイルとして認識）
  content_type = "text/html"
  # 変更検出用の etag（ファイル内容が変わったときだけ再アップロード）
  # etag = filemd5(website/index.html.tpl)
  # オブジェクトへのアクセス権限（プライベート）
  acl = "private"

  # 他リソースの作成後にアップロードを実行
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.public_access,
    aws_s3_bucket_policy.static_site_policy,
    aws_s3_bucket_website_configuration.website
  ]
}
