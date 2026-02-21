# # ===== SageMaker モデル =====
# # 注: Notebook インスタンスで学習完了後、以下を実行してください：
# # 1. model_data_url を実際の S3 パスに更新
# # 2. terraform apply を実行

# # 組み込みアルゴリズムのイメージ URI を動的に取得
# data "aws_sagemaker_prebuilt_ecr_image" "deepar" {
#   repository_name = "forecasting-deepar"
#   image_tag       = "latest"
# }

# resource "aws_sagemaker_model" "deepar_model" {
#   name               = "${local.project_name}-model"
#   execution_role_arn = aws_iam_role.sagemaker_role.arn

#   primary_container {
#     image          = data.aws_sagemaker_prebuilt_ecr_image.deepar.registry_path
#     model_data_url = "${local.output_path}/<path>/output/model.tar.gz"   # pathは実機を確認して変更必要。パスの例：forecasting-deepar-2026-01-10-02-08-21-129
#   }

#   tags = local.common_tags
# }

# # ===== SageMaker エンドポイント設定 =====
# # 目的: モデル推論用のエンドポイント設定
# resource "aws_sagemaker_endpoint_configuration" "deepar_endpoint_config" {
#   name = "${local.project_name}-endpoint-config"

#   production_variants {
#     variant_name           = "AllTraffic"
#     model_name             = aws_sagemaker_model.deepar_model.name
#     instance_type          = "ml.m5.large"
#     initial_instance_count = 1
#     initial_variant_weight = 1.0
#   }

#   tags = local.common_tags
# }

# # ===== SageMaker エンドポイント =====
# # 目的: REST API として推論エンドポイントをデプロイ
# resource "aws_sagemaker_endpoint" "deepar_endpoint" {
#   name                 = "${local.project_name}-endpoint"
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.deepar_endpoint_config.name

#   tags = local.common_tags
# }

# # ===== 出力値 =====
# output "sagemaker_role_arn" {
#   description = "SageMaker 実行ロール ARN"
#   value       = aws_iam_role.sagemaker_role.arn
# }

# output "sagemaker_notebook_instance_name" {
#   description = "SageMaker Notebook インスタンス名"
#   value       = aws_sagemaker_notebook_instance.deepar_notebook.name
# }

# output "notebook_instance_url" {
#   description = "SageMaker Notebook インスタンスへのアクセス URL"
#   value       = aws_sagemaker_notebook_instance.deepar_notebook.url
# }

# output "sagemaker_model_name" {
#   description = "SageMaker モデル名"
#   value       = aws_sagemaker_model.deepar_model.name
# }

# output "sagemaker_endpoint_name" {
#   description = "SageMaker 推論エンドポイント名"
#   value       = aws_sagemaker_endpoint.deepar_endpoint.name
# }

# output "s3_training_data_location" {
#   description = "トレーニングデータのS3パス"
#   value       = local.training_data_uri
# }

# output "s3_output_path" {
#   description = "モデル出力のS3パス"
#   value       = local.output_path
# }