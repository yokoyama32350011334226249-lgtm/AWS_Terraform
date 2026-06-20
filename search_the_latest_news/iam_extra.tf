# ===== アイテム管理 Lambda 用 IAM ロール =====
resource "aws_iam_role" "items_lambda_role" {
  name = "news-items-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "items_lambda_policy" {
  name        = "NewsItemsLambdaPolicy"
  description = "DynamoDB アクセス + CloudWatch ログ"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.watch_items.arn
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

resource "aws_iam_role_policy_attachment" "items_lambda_attach" {
  role       = aws_iam_role.items_lambda_role.name
  policy_arn = aws_iam_policy.items_lambda_policy.arn
}


# ===== 定期検索 Lambda 用 IAM ロール =====
resource "aws_iam_role" "scheduled_lambda_role" {
  name = "news-scheduled-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "scheduled_lambda_policy" {
  name        = "NewsScheduledLambdaPolicy"
  description = "DynamoDB + Bedrock + SES + CloudWatch ログ"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.watch_items.arn
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
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

resource "aws_iam_role_policy_attachment" "scheduled_lambda_attach" {
  role       = aws_iam_role.scheduled_lambda_role.name
  policy_arn = aws_iam_policy.scheduled_lambda_policy.arn
}
