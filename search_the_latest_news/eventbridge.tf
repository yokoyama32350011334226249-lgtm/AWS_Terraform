# ===== Lambda 関数（定期検索・メール通知用） =====
data "archive_file" "lambda_scheduled_zip" {
  type        = "zip"
  source_file = "${path.module}/code/lambda_scheduled_search.py"
  output_path = "${path.module}/code/lambda_scheduled_search.zip"
}

resource "aws_lambda_function" "scheduled_search_lambda" {
  function_name    = "news-scheduled-search-lambda"
  role             = aws_iam_role.scheduled_lambda_role.arn
  handler          = "lambda_scheduled_search.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.lambda_scheduled_zip.output_path
  source_code_hash = data.archive_file.lambda_scheduled_zip.output_base64sha256
  # 複数アイテムを順次処理するため余裕を持ったタイムアウトを設定
  timeout          = 300

  environment {
    variables = {
      BRAVE_API_KEY    = var.brave_api_key
      DYNAMODB_TABLE   = aws_dynamodb_table.watch_items.name
      SES_SENDER_EMAIL = var.ses_sender_email
    }
  }
}

# ===== EventBridge ルール（定期実行スケジュール） =====
resource "aws_cloudwatch_event_rule" "daily_search" {
  name                = "news-daily-search"
  description         = "DynamoDB に登録されたアイテムを定期検索してメール通知"
  schedule_expression = var.search_schedule
}

resource "aws_cloudwatch_event_target" "search_lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_search.name
  target_id = "ScheduledSearchLambda"
  arn       = aws_lambda_function.scheduled_search_lambda.arn
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_search_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_search.arn
}
