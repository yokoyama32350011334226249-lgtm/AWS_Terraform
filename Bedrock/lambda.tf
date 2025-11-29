# ===== Lambda 関数と IAM ロール・ポリシーの設定 =====
# このファイルでは、Bedrock API を呼び出すサーバーレス関数と、その実行権限を定義しています

# ===== IAM ロール（Lambda の実行権限の基盤） =====
# 目的: Lambda 関数が AWS リソースにアクセスするための ID/権限を定義
# 機能:
#   - Lambda サービスが このロールを引き受ける（AssumeRole）ことを許可
#   - 後続で定義するポリシーはこのロールにアタッチされる
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  # ロール引き受けポリシー：Lambda サービスが このロールを使用することを許可
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      # Lambda サービスのみが このロールを引き受け可能
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# ===== IAM ポリシー（Lambda の具体的なアクセス権限） =====
# 目的: Lambda 関数に Bedrock API へのアクセス権限と CloudWatch ログ出力権限を付与
# 構成: 2つの権限セット
#   1. Bedrock サービス：AI モデル呼び出し用
#   2. CloudWatch ログ：関数の実行ログ記録用
resource "aws_iam_policy" "lambda_bedrock_policy" {
  name        = "LambdaBedrockPolicy"
  description = "Allow Lambda to access Bedrock"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # ===== Bedrock API アクセス権限 =====
        # 目的: Lambda から Bedrock の AI モデルを呼び出すことを許可
        Effect   = "Allow"
        # bedrock:* はすべての Bedrock アクション（InvokeModel など）を許可
        Action   = ["bedrock:*"]
        # すべてのリソースに対して有効（制本番環境では特定のモデルARNに制限推奨）
        Resource = "*"
      },
      {
        # ===== CloudWatch ログ出力権限 =====
        # 目的: Lambda の実行ログを CloudWatch Logs に記録することを許可
        Effect   = "Allow"
        Action   = [
          # ログストリームが属するロググループを作成
          "logs:CreateLogGroup",
          # ログを受け取るストリームを作成
          "logs:CreateLogStream",
          # ログイベントをストリームに書き込み
          "logs:PutLogEvents"
        ]
        # すべてのロググループ/ストリームに対して有効
        Resource = "*"
      }
    ]
  })
}

# ===== 基本実行ロールのアタッチ =====
# 目的: AWS が提供する既成の基本ポリシーを Lambda ロールにアタッチ
# 機能: VPC アクセス（オプション）や EC2 ネットワークインターフェース管理に必要
resource "aws_iam_role_policy_attachment" "attach_lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  # AWSLambdaBasicExecutionRole：CloudWatch ログへの標準的な書き込み権限を提供
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ===== カスタム Bedrock ポリシーのアタッチ =====
# 目的: 上記で定義したカスタムポリシーを Lambda ロールに関連付け
# 機能: Lambda が Bedrock API を呼び出し可能になる
resource "aws_iam_role_policy_attachment" "attach_lambda_bedrock" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_bedrock_policy.arn
}

# ===== Lambda 関数のパッケージ化（ZIP ファイル作成） =====
# 目的: Python スクリプトを ZIP ファイルに圧縮し、Lambda へのデプロイ準備
# プロセス:
#   1. lambda_function.py を入力
#   2. ZIP 形式に圧縮
#   3. 出力ファイルを lambda_function.zip として保存
data "archive_file" "lambda_zip" {
  # 圧縮形式
  type = "zip"
  # 圧縮対象：Lambda関数のPythonスクリプト
  source_file = "${path.module}/lambda_function.py"
  # 圧縮後の出力先
  output_path = "${path.module}/lambda_function.zip"
}

# ===== Lambda 関数（Bedrock AI モデル呼び出し用） =====
# 目的: HTTP API からのリクエストを受け取り、Bedrock の Claude AI モデルを呼び出し、結果を返す
# 処理フロー: API Gateway → Lambda → Bedrock → 応答を Lambda → API Gateway → クライアント
resource "aws_lambda_function" "bedrock_lambda" {
  # Lambda 関数の識別名
  function_name = var.lambda_function_name
  # この関数に付与する IAM ロール（上記で定義）
  role = aws_iam_role.lambda_role.arn
  # 関数呼び出しのエントリーポイント（ファイル名.関数名）
  handler = "lambda_function.handler"
  # Python ランタイムバージョン
  runtime = "python3.11"
  # デプロイするコードの ZIP ファイル
  filename = data.archive_file.lambda_zip.output_path
  # コードの変更検出用ハッシュ値
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  # 環境変数の設定
  environment {
    variables = {
      BEDROCK_MODEL_ID = "amazon.titan-text-lite-v1"  # ← 申請不要モデル
    }
  }
}
