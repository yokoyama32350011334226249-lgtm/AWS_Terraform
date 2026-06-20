# ===== Lambda 関数（アイテム CRUD 用） =====
data "archive_file" "lambda_items_zip" {
  type        = "zip"
  source_file = "${path.module}/code/lambda_items.py"
  output_path = "${path.module}/code/lambda_items.zip"
}

resource "aws_lambda_function" "items_lambda" {
  function_name    = "news-items-lambda"
  role             = aws_iam_role.items_lambda_role.arn
  handler          = "lambda_items.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.lambda_items_zip.output_path
  source_code_hash = data.archive_file.lambda_items_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.watch_items.name
      SES_SENDER_EMAIL = var.ses_sender_email
    }
  }
}

# ===== API Gateway（アイテム管理用） =====
resource "aws_apigatewayv2_api" "items_api" {
  name          = "news-items-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Api-Key"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "items_integration" {
  api_id                 = aws_apigatewayv2_api.items_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.items_lambda.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "items_get" {
  api_id    = aws_apigatewayv2_api.items_api.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.items_integration.id}"
}

resource "aws_apigatewayv2_route" "items_post" {
  api_id    = aws_apigatewayv2_api.items_api.id
  route_key = "POST /items"
  target    = "integrations/${aws_apigatewayv2_integration.items_integration.id}"
}

resource "aws_apigatewayv2_route" "items_delete" {
  api_id    = aws_apigatewayv2_api.items_api.id
  route_key = "DELETE /items/{item_id}"
  target    = "integrations/${aws_apigatewayv2_integration.items_integration.id}"
}

resource "aws_apigatewayv2_stage" "items_default" {
  api_id      = aws_apigatewayv2_api.items_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "items_apigw_invoke" {
  statement_id  = "AllowItemsAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.items_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.items_api.execution_arn}/*/*"
}
