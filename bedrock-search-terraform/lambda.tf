# ───────────────────────────────────────────
# Lambda パッケージ（zip）
# ───────────────────────────────────────────

data "archive_file" "bedrock_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src/bedrock"
  output_path = "${path.module}/.build/bedrock_lambda.zip"
}

data "archive_file" "search_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src/search"
  output_path = "${path.module}/.build/search_lambda.zip"
}

# ───────────────────────────────────────────
# Lambda②: Search（Google Custom Search 呼び出し）
# Bedrock Lambda より先に作成する必要があるため先に定義
# ───────────────────────────────────────────

resource "aws_lambda_function" "search" {
  function_name    = "${var.project_name}-search"
  role             = aws_iam_role.lambda_search.arn
  runtime          = "python3.13"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.search_lambda.output_path
  source_code_hash = data.archive_file.search_lambda.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.api_keys.name
    }
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "search_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.search.function_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

# ───────────────────────────────────────────
# Lambda①: Bedrock（オーケストレーター）
# ───────────────────────────────────────────

resource "aws_lambda_function" "bedrock" {
  function_name    = "${var.project_name}-bedrock"
  role             = aws_iam_role.lambda_bedrock.arn
  runtime          = "python3.13"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.bedrock_lambda.output_path
  source_code_hash = data.archive_file.bedrock_lambda.output_base64sha256
  timeout          = 120 # Bedrock + 検索の合計を考慮して長めに設定

  environment {
    variables = {
      BEDROCK_MODEL_ID     = var.bedrock_model_id
      SEARCH_FUNCTION_NAME = aws_lambda_function.search.function_name
    }
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "bedrock_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.bedrock.function_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

# ───────────────────────────────────────────
# API Gateway → Lambda の実行許可
# ───────────────────────────────────────────

resource "aws_lambda_permission" "apigw_bedrock" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
