output "frontend_url" {
  description = "S3 静的ウェブサイトのURL"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "api_endpoint" {
  description = "API Gateway エンドポイント（/bedrock）"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/bedrock"
}

output "bedrock_lambda_name" {
  description = "Bedrock Lambda 関数名"
  value       = aws_lambda_function.bedrock.function_name
}

output "search_lambda_name" {
  description = "Search Lambda 関数名"
  value       = aws_lambda_function.search.function_name
}

output "secret_name" {
  description = "Secrets Manager シークレット名"
  value       = aws_secretsmanager_secret.api_keys.name
}
