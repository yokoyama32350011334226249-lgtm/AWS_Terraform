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

  # ウェブサイトホスティング設定
  website {
    # メインページとして機能するドキュメント
    index_document = "index.html"
    # エラーが発生した場合に表示されるドキュメント（SPA対応）
    error_document = "index.html"
  }

  # 公開読み取りアクセス許可リスト（誰でもファイルを読める）
  acl = "public-read"
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
      }
    ]
  })
}

# ===== S3 オブジェクトアップロード（ウェブサイトのトップページ） =====
# 目的: HTML ファイルを S3 バケットに自動的にアップロード
# 機能: Terraform の apply 時に index.html がバケットにアップロードされる
resource "aws_s3_bucket_object" "index_html" {
  # アップロード先のバケット
  bucket = aws_s3_bucket.static_site.id
  # バケット内でのオブジェクトのキー（パス）
  key = "index.html"
  # ローカルファイルのパス（相対パス）
  source = "${path.module}/website/index.html"
  # ファイルの MIME タイプ（HTML ファイルとして認識）
  content_type = "text/html"
  # オブジェクトへのアクセス権限（公開読み取り）
  acl = "public-read"
}
