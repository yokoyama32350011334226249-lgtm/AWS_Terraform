# ===== チャット Lambda 用 IAM ロール =====
resource "aws_iam_role" "chat_lambda_role" {
  name = "news-search-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "chat_lambda_policy" {
  name        = "ChatLambdaBedrockPolicy"
  description = "Bedrock 呼び出し + CloudWatch ログ"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:*"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chat_lambda_basic" {
  role       = aws_iam_role.chat_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "chat_lambda_bedrock" {
  role       = aws_iam_role.chat_lambda_role.name
  policy_arn = aws_iam_policy.chat_lambda_policy.arn
}

# ===== チャット Lambda 関数 =====
data "archive_file" "lambda_chat_zip" {
  type        = "zip"
  source_file = "${path.module}/code/lambda_function.py"
  output_path = "${path.module}/code/lambda_function.zip"
}

resource "aws_lambda_function" "chat_lambda" {
  function_name    = "news-search-lambda"
  role             = aws_iam_role.chat_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.lambda_chat_zip.output_path
  source_code_hash = data.archive_file.lambda_chat_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      BRAVE_API_KEY = var.brave_api_key
    }
  }
}
