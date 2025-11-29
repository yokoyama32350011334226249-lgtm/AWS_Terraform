# ===== API Gateway の設定 =====
# このファイルでは、クライアントからのリクエストを受け付け、Lambda 関数に転送するための
# HTTP API エンドポイントを定義しています

# ===== HTTP API（REST インターフェース） =====
# 目的: クライアント（ウェブブラウザ、モバイルアプリなど）からのリクエストを受け付ける
# 機能:
#   - HTTP プロトコルをサポート（REST API）
#   - Lambda 関数へのリクエスト転送
#   - インターネットから直接アクセス可能な URL を提供
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_name
  # HTTP API を使用（REST API の一種、シンプルで低コスト）
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["https://my-bedrock-static-site.s3.ap-northeast-1.amazonaws.com"] # 許可するオリジン（* にすると全許可）
    allow_methods = ["GET", "POST", "OPTIONS"]                         # 許可するメソッド（必ず OPTIONS を含める）
    allow_headers = ["Content-Type", "Authorization", "X-Api-Key"]     # 許可するリクエストヘッダ
    expose_headers = ["x-custom-header"]                              # 必要に応じて公開するレスポンスヘッダ
    max_age        = 3600                                              # ブラウザがプリフライト結果をキャッシュする秒数
    allow_credentials = false                                          # クッキー等を許可する場合は true に
  }
}

# ===== Lambda 統合（API → Lambda の接続） =====
# 目的: API Gateway が受け取ったリクエストを Lambda 関数に転送するための橋渡し
# 機能:
#   - AWS_PROXY 統合：Lambda が完全なレスポンスを制御
#   - Payload format version 2.0：最新の API Gateway v2 フォーマット対応
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.api.id
  # AWS_PROXY：Lambda が HTTP ステータスコードなど全てを返す
  integration_type = "AWS_PROXY"
  # HTTP メソッド：POST リクエストを Lambda に転送
  integration_method = "POST"
  # Lambda 関数の ARN（どの関数にリクエストを転送するか）
  integration_uri = aws_lambda_function.bedrock_lambda.arn
  # API Gateway v2 フォーマット
  payload_format_version = "2.0"
}

# ===== ルート（エンドポイント設定） =====
# 目的: 特定の HTTP メソッド・パスのリクエストを Lambda に転送するルール
# 例: POST https://api-endpoint.com/bedrock → Lambda 関数に転送
resource "aws_apigatewayv2_route" "route" {
  api_id = aws_apigatewayv2_api.api.id
  # ルートキー：HTTP メソッド + パス
  # POST /bedrock にマッチするリクエストを処理
  route_key = "POST /bedrock"
  # リクエスト転送先：Lambda 統合
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# # ===== MOCK 統合（プリフライトリクエスト用） =====
# # 目的: API Gateway が受け取ったリクエストを MOCK 統合に転送するための橋渡し
# resource "aws_apigatewayv2_integration" "mock_integration" {
#   api_id = aws_apigatewayv2_api.api.id
#   # AWS_PROXY：Lambda が HTTP ステータスコードなど全てを返す
#   integration_type = "MOCK"
#   # HTTP メソッド：OPTIONS リクエストを MOCK に転送
#   integration_method = "OPTIONS"
#   # API Gateway v2 フォーマット
#   payload_format_version = "2.0"
# }

# # ===== ルート（エンドポイント設定） =====
# # 目的: 特定の HTTP メソッド・パスのリクエストを MOCK 統合に転送するルール
# # 例: OPTIONS https://api-endpoint.com/bedrock → MOCK 統合に転送
# resource "aws_apigatewayv2_route" "options_route" {
#   api_id = aws_apigatewayv2_api.api.id
#   # ルートキー：HTTP メソッド + パス
#   # OPTIONS /bedrock にマッチするリクエストを処理
#   route_key = "OPTIONS /bedrock"
#   # リクエスト転送先：Lambda 統合
#   target = "integrations/${aws_apigatewayv2_integration.mock_integration.id}"
# }

# ===== ステージ（デプロイメント環境） =====
# 目的: API を実際にインターネットに公開するための環境設定
# 機能:
#   - $default：デフォルトステージ（本番環境相当）
#   - auto_deploy：設定変更時に自動的に反映
resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.api.id
  # ステージ名：$default はデフォルトステージ（API URL に含まれない）
  name = "$default"
  # 設定変更が自動的にデプロイされる
  auto_deploy = true
}

# ===== Lambda 実行権限（API → Lambda 呼び出し許可） =====
# 目的: API Gateway が Lambda 関数を呼び出すことを AWS IAM で許可
# 機能: API Gateway からのリクエストに限定した Lambda 実行権限を付与
# セキュリティ: source_arn で特定の API からの呼び出しのみに制限
resource "aws_lambda_permission" "apigw_lambda" {
  # ステートメント ID（権限の識別子）
  statement_id = "AllowAPIGatewayInvoke"
  # 許可アクション：Lambda 関数の呼び出し
  action = "lambda:InvokeFunction"
  # 対象 Lambda 関数
  function_name = aws_lambda_function.bedrock_lambda.function_name
  # 呼び出し元：API Gateway サービス
  principal = "apigateway.amazonaws.com"
  # 呼び出し元の制限：この API Gateway からのリクエストのみ
  # /* の 2つは HTTP メソッドと パス部分にマッチ（全て許可）
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
