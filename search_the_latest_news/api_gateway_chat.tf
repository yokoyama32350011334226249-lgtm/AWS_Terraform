# ===== チャット用 API Gateway =====
resource "aws_apigatewayv2_api" "chat_api" {
  name          = "news-search-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "https://${aws_s3_bucket.static_site.bucket}.s3.ap-northeast-1.amazonaws.com",
      "http://${aws_s3_bucket_website_configuration.static_site_website.website_endpoint}"
    ]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization", "X-Api-Key"]
    expose_headers    = ["x-custom-header"]
    max_age           = 3600
    allow_credentials = false
  }
}

resource "aws_apigatewayv2_integration" "chat_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.chat_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.chat_lambda.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chat_route" {
  api_id    = aws_apigatewayv2_api.chat_api.id
  route_key = "POST /bedrock"
  target    = "integrations/${aws_apigatewayv2_integration.chat_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "chat_default" {
  api_id      = aws_apigatewayv2_api.chat_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "chat_apigw_invoke" {
  statement_id  = "AllowChatAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat_api.execution_arn}/*/*"
}
