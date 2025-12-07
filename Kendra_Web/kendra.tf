# --- Kendra Web Crawler 用メイン設定ファイル ---
# Kendra Index と Web Crawler データソースを作成します

# --- Kendra Index 用 IAM ロール ---
resource "aws_iam_role" "kendra_index_role" {
  name = "kendra-index-role"

  # Kendra がインデックス作成・更新を行うために必要な信頼ポリシー。
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "kendra.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Kendra Index 用の IAM ポリシー
resource "aws_iam_role_policy" "kendra_index_policy" {
  name = "kendra-index-policy"
  role = aws_iam_role.kendra_index_role.id

  # Kendra Index が CloudWatch Logs などに書き込むための権限。
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kendra_index" "this" {
  name        = var.kendra_index_name
  role_arn    = aws_iam_role.kendra_index_role.arn   # 作成した IAM ロールを指定
  edition     = "DEVELOPER_EDITION"
}


# --- Web Crawler 用 IAM ロール ---
resource "aws_iam_role" "kendra_datasource_role" {
  name = "kendra-datasource-role"

  # Webcrawler データソースが AssumeRole するための信頼ポリシー
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "kendra.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Webcrawler 用の IAM ポリシー
resource "aws_iam_role_policy" "kendra_datasource_policy" {
  name = "kendra-datasource-policy"
  role = aws_iam_role.kendra_datasource_role.id

  # Webcrawler がログ出力や各種処理を行うのに必要な権限
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kendra:BatchPutDocument",
          "kendra:BatchDeleteDocument"
        ],
        Resource = aws_kendra_index.this.arn
      }
    ]
  })
}

resource "aws_kendra_data_source" "webcrawler" {
  index_id = aws_kendra_index.this.id
  name     = "kendra-webcrawler"       # データソース名
  type     = "WEBCRAWLER"              # Webcrawler を指定
  role_arn = aws_iam_role.kendra_datasource_role.arn  # Webcrawler 用の IAM ロール

  configuration {
    web_crawler_configuration {
      urls {
        seed_url_configuration {
          web_crawler_mode = "HOST_ONLY"   # ホストのみクロール
          seed_urls = [var.seed_url]   # クロール開始 URL（tfvars から外出し）
        }
      }
      crawl_depth       = 2            # クロールの深さ（リンクの追跡階層）
      max_content_size_per_page_in_mega_bytes = 50  # 1ページあたりの最大コンテンツサイズ（MB）
      max_links_per_page = 100         # 1ページあたりの最大リンク数
      max_urls_per_minute_crawl_rate = 300  # 1分あたりの最大クロール数      
      authentication_configuration {}  # 認証が必要な場合はここに追加
    }
  }
}
