# ===== Terraform 変数値 =====
# このファイルでは、variables.tf で定義した変数に実際の値を割り当てています

# デプロイするAWSリージョン
region               = "ap-northeast-1"

# S3 バケット名: 静的ウェブサイト（HTML）をホストするバケット
# グローバルに一意の名前である必要があります
s3_bucket_name       = "my-bedrock-static-site"

# Lambda 関数名: Bedrock API を呼び出すサーバーレス関数
lambda_function_name = "bedrock-lambda"

# API Gateway の名前: HTTP API として機能し、クライアントからのリクエストを Lambda に転送
api_name             = "bedrock-api"

# IAM ロール名: Lambda 関数に付与される権限（Bedrock アクセスと CloudWatch ログ出力）を管理
lambda_role_name     = "bedrock-lambda-role"
