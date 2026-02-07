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
  s3_bucket         = "sagemaker-20260207"
  training_data_uri = "s3://${local.s3_bucket}/nikkei-deepar/train"
  output_path       = "s3://${local.s3_bucket}/nikkei-deepar/output"
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

# ===== SageMaker モデル =====
# 注: Notebook インスタンスで学習完了後、以下を実行してください：
# 1. model_data_url を実際の S3 パスに更新
# 2. terraform apply を実行
resource "aws_sagemaker_model" "deepar_model" {
  name               = "${local.project_name}-model"
  execution_role_arn = aws_iam_role.sagemaker_role.arn

  primary_container {
    image = "246618743249.dkr.ecr.ap-northeast-1.amazonaws.com/sagemaker-forecasting-deepar:1"
    # Notebook で学習完了後、以下を実際の S3 パスに置き換え：
    # s3://sagemaker-20260207/nikkei-deepar/output/<model-artifact-folder>/model.tar.gz
    model_data_url = "${local.output_path}/model-artifacts-placeholder/model.tar.gz"
  }

  tags = local.common_tags
}

# ===== SageMaker エンドポイント設定 =====
# 目的: モデル推論用のエンドポイント設定
resource "aws_sagemaker_endpoint_configuration" "deepar_endpoint_config" {
  name = "${local.project_name}-endpoint-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.deepar_model.name
    instance_type          = "ml.m5.large"
    initial_instance_count = 1
    initial_variant_weight = 1.0
  }

  tags = local.common_tags
}

# ===== SageMaker エンドポイント =====
# 目的: REST API として推論エンドポイントをデプロイ
resource "aws_sagemaker_endpoint" "deepar_endpoint" {
  name                 = "${local.project_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.deepar_endpoint_config.name

  tags = local.common_tags
}

# ===== 出力値 =====
output "sagemaker_role_arn" {
  description = "SageMaker 実行ロール ARN"
  value       = aws_iam_role.sagemaker_role.arn
}

output "sagemaker_notebook_instance_name" {
  description = "SageMaker Notebook インスタンス名"
  value       = aws_sagemaker_notebook_instance.deepar_notebook.name
}

output "notebook_instance_url" {
  description = "SageMaker Notebook インスタンスへのアクセス URL"
  value       = aws_sagemaker_notebook_instance.deepar_notebook.url
}

output "sagemaker_model_name" {
  description = "SageMaker モデル名"
  value       = aws_sagemaker_model.deepar_model.name
}

output "sagemaker_endpoint_name" {
  description = "SageMaker 推論エンドポイント名"
  value       = aws_sagemaker_endpoint.deepar_endpoint.name
}

output "s3_training_data_location" {
  description = "トレーニングデータのS3パス"
  value       = local.training_data_uri
}

output "s3_output_path" {
  description = "モデル出力のS3パス"
  value       = local.output_path
}
