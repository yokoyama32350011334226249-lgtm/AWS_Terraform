# ───────────────────────────────────────────
# IAM: Bedrock Lambda 用ロール
# ───────────────────────────────────────────

resource "aws_iam_role" "lambda_bedrock" {
  name = "${var.project_name}-lambda-bedrock-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_basic" {
  role       = aws_iam_role.lambda_bedrock.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_bedrock_policy" {
  name = "${var.project_name}-lambda-bedrock-policy"
  role = aws_iam_role.lambda_bedrock.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Bedrockモデル呼び出し
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      },
      {
        # Lambda②（検索用）の呼び出し
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.search.arn
      },
      {
        # Secrets Manager からシークレット取得（検索結果要約時に不要だが念のため）
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.api_keys.arn
      }
    ]
  })
}

# ───────────────────────────────────────────
# IAM: Search Lambda 用ロール
# ───────────────────────────────────────────

resource "aws_iam_role" "lambda_search" {
  name = "${var.project_name}-lambda-search-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_search_basic" {
  role       = aws_iam_role.lambda_search.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_search_policy" {
  name = "${var.project_name}-lambda-search-policy"
  role = aws_iam_role.lambda_search.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Secrets Manager から Google APIキー取得
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.api_keys.arn
      }
    ]
  })
}
