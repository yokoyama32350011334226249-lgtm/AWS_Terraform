# ===== SageMaker AIモデル構築・デプロイメント設定 =====
# 目的: AWS SageMaker を使用して、時系列予測モデル（DeepAR）を学習・デプロイ
# 注: 学習・推論は Notebook インスタンスで手動実行

# ===== ローカル変数の定義 =====
locals {
  project_name = "nikkei-deepar"
  common_tags = {
    Project     = local.project_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
  training_data_uri = "s3://${var.s3_bucket}/nikkei-deepar/train"
  output_path       = "s3://${var.s3_bucket}/nikkei-deepar/output"
}

# ===== SageMaker 実行用 IAM ロール =====
# 目的: Notebook インスタンス、学習ジョブ、推論エンドポイントが使用するロール
resource "aws_iam_role" "sagemaker_role" {
  name = "${local.project_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# ===== SageMaker 用カスタムポリシー =====
# 目的: S3、ECR、CloudWatch ログへのアクセスを許可
resource "aws_iam_policy" "sagemaker_policy" {
  name        = "${local.project_name}-policy"
  description = "Allow SageMaker to access required AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.sagemaker_role.arn
      }
    ]
  })

  tags = local.common_tags
}

# ===== ポリシーをロールにアタッチ =====
resource "aws_iam_role_policy_attachment" "sagemaker_policy_attach" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.sagemaker_policy.arn
}

# AWS 提供のフルアクセスポリシーをアタッチ（開発環境向け）
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# ===== SageMaker Notebook インスタンス =====
# 目的: Jupyter Lab 環境で学習・推論を手動実行
resource "aws_sagemaker_notebook_instance" "deepar_notebook" {
  name                   = "${local.project_name}-notebook"
  instance_type          = "ml.t3.medium"
  role_arn               = aws_iam_role.sagemaker_role.arn

  tags = local.common_tags
}
