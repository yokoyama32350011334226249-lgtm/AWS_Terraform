# Bedrock Web Search - Terraform

Amazon Bedrock (Claude) と Google Custom Search API を使ったWeb検索・要約システムのインフラ構成です。

## アーキテクチャ

```
ユーザー（S3 静的サイト）
        ↓ POST /bedrock  { "topic": "..." }
API Gateway (HTTP API v2)
        ↓
Lambda① bedrock（オーケストレーター）
        ├─ Step1: Bedrock Claude → 検索クエリ生成
        ├─ Step2: Lambda② search を呼び出し
        │           └─ Google Custom Search API
        └─ Step3: Bedrock Claude → 検索結果を要約
        ↓
フロントに { topic, search_query, search_results, summary } を返却
```

## ファイル構成

```
terraform/
├── main.tf                      # プロバイダ設定
├── variables.tf                 # 変数定義
├── locals.tf                    # 共通タグなど
├── secrets.tf                   # Secrets Manager
├── iam.tf                       # IAMロール・ポリシー
├── lambda.tf                    # Lambda関数×2
├── apigateway.tf                # API Gateway v2
├── s3.tf                        # S3静的ホスティング
├── outputs.tf                   # 出力値
├── index.html.tftpl             # フロントエンドHTMLテンプレート
├── terraform.tfvars.example     # 変数サンプル（要コピー）
├── .gitignore
└── lambda_src/
    ├── bedrock/
    │   └── lambda_function.py   # Bedrock呼び出し＋オーケストレーション
    └── search/
        └── lambda_function.py   # Google Custom Search API呼び出し
```

## デプロイ手順

### 1. 事前準備

- Google Cloud Console で Custom Search APIキーを取得
- Programmable Search Engine で検索エンジンID (cx) を取得
- Bedrockコンソールで `claude-sonnet-4-6` のモデルアクセスを有効化

### 2. 変数ファイルの作成

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して実際の値を入力
```

### 3. デプロイ

```bash
terraform init
terraform plan
terraform apply
```

### 4. 出力の確認

```
frontend_url    = "http://xxxx.s3-website-ap-northeast-1.amazonaws.com"
api_endpoint    = "https://xxxx.execute-api.ap-northeast-1.amazonaws.com/bedrock"
```

`frontend_url` をブラウザで開くと動作確認できます。

### 5. 削除

```bash
terraform destroy
```

## 注意事項

- `terraform.tfvars` には APIキーが含まれるため **Git にコミットしない**でください
- Bedrock の `global.*` モデルIDはクロスリージョン推論を使用します。
  リージョンを変更する場合は `bedrock_model_id` も合わせて確認してください
- Lambda① のタイムアウトは 120 秒に設定しています（Bedrock×2回 + 検索の合計）
- API Gateway の CORS は `*` を許可しています。本番環境では S3 の URL に絞ることを推奨します
