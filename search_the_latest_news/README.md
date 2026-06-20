# search_the_latest_news

Brave Search API と Amazon Bedrock (Claude) を組み合わせた、最新情報の定期監視・メール通知システムです。  
Terraform によって AWS リソース一式をプロビジョニングします。

---

## システム概要

登録したキーワードを定期的に自動検索し、その結果を AI がまとめてメールで通知します。  
また、Web UI からチャット形式で Claude と会話することもできます。

---

## アーキテクチャ

```
[ブラウザ (S3 静的サイト)]
        │
        ├─ チャット ──────────────────────────────────────────────────────┐
        │   POST /bedrock                                                │
        │   [API Gateway (chat)] → [Lambda: lambda_function.py]         │
        │                            └─ Brave Search API (tool)         │
        │                            └─ Amazon Bedrock (Claude)         │
        │                                                                │
        └─ 監視アイテム登録/一覧/削除 ─────────────────────────────────────┘
            GET|POST|DELETE /items
            [API Gateway (items)] → [Lambda: lambda_items.py]
                                        └─ DynamoDB (watch_items テーブル)

[EventBridge (定期スケジュール)]
    └─ [Lambda: lambda_scheduled_search.py]
            ├─ DynamoDB からアイテム一覧を取得
            ├─ Brave Search API (tool) で各キーワードを検索
            ├─ Amazon Bedrock (Claude) で結果をまとめ
            └─ Amazon SES でメール送信
```

---

## AWS リソース一覧

| リソース | 名前 | 役割 |
|---|---|---|
| S3 バケット | `news-search-static-site` | Web UI (index.html) をホスティング |
| API Gateway | `news-search-api` | チャット用エンドポイント (`POST /bedrock`) |
| API Gateway | `news-items-api` | アイテム CRUD エンドポイント (`/items`) |
| Lambda | `news-search-lambda` | チャット用 (Bedrock + Brave Search) |
| Lambda | `news-items-lambda` | アイテムの登録・取得・削除 |
| Lambda | `news-scheduled-search-lambda` | 定期検索・SES 通知 |
| DynamoDB | `news-watch-items` | 監視アイテム (キーワード・メールアドレス) を管理 |
| EventBridge | `news-daily-search` | 定期実行スケジュール |
| SES | ─ | メール通知の送信 |

---

## ファイル構成

```
search_the_latest_news/
├── code/
│   ├── lambda_function.py          # チャット用 Lambda
│   ├── lambda_items.py             # アイテム CRUD Lambda
│   └── lambda_scheduled_search.py  # 定期検索・通知 Lambda
├── website/
│   └── index.html.tmp              # Web UI テンプレート (templatefile で URL を埋め込み)
├── api_gateway_chat.tf             # チャット用 API Gateway
├── api_items.tf                    # アイテム管理 API Gateway + Lambda
├── dynamodb.tf                     # DynamoDB テーブル
├── eventbridge.tf                  # EventBridge スケジュール + 定期検索 Lambda
├── iam_extra.tf                    # アイテム/定期検索 Lambda 用 IAM
├── lambda_chat.tf                  # チャット Lambda + IAM
├── s3_static.tf                    # S3 バケット + index.html アップロード
├── ses.tf                          # SES メールアドレス検証
├── main.tf                         # ルート設定
├── provider.tf                     # AWS プロバイダー (ap-northeast-1)
└── variables.tf / terraform.tfvars # 変数定義・値
```

---

## 変数

| 変数名 | 説明 | 例 |
|---|---|---|
| `allowed_ip` | S3 へのアクセスを許可する IP (CIDR) | `"203.0.113.1/32"` |
| `brave_api_key` | Brave Search API キー | `"BSAxxxxx"` |
| `ses_sender_email` | SES で検証済みの送信元メールアドレス | `"you@example.com"` |
| `search_schedule` | EventBridge スケジュール式 | `"rate(1 day)"` / `"cron(0 9 * * ? *)"` |

### terraform.tfvars の例

```hcl
allowed_ip       = "203.0.113.1/32"
brave_api_key    = "BSAxxxxx"
ses_sender_email = "you@example.com"
search_schedule  = "rate(1 day)"
```

---

## デプロイ手順

### 前提条件

- Terraform >= 1.6.0
- AWS CLI 設定済み（`AdministratorAccess` 相当の権限）
- Brave Search API キーを取得済み
- SES で送信元メールアドレスの検証が完了していること

> **SES サンドボックス環境の注意**  
> デフォルトでは送信先も検証済みアドレスのみ受信可能です。  
> 本番運用する場合は AWS コンソールの SES > Account dashboard から「本番アクセス」を申請してください。

### 手順

```bash
cd search_the_latest_news

# 変数を設定
cp terraform.tfvars.example terraform.tfvars  # ない場合は直接編集
# terraform.tfvars に各変数を記入

terraform init
terraform plan
terraform apply
```

`apply` 完了後、出力される S3 の Web サイト URL にブラウザでアクセスできます。

---

## 処理フロー

### チャット機能

1. ブラウザから `POST /bedrock` にメッセージを送信
2. Lambda (Claude) が必要に応じて Brave Search API を呼び出す (tool use)
3. 検索結果を踏まえた回答をブラウザに返す

### 定期検索・通知機能

1. EventBridge が設定したスケジュールで Lambda を起動
2. Lambda が DynamoDB に登録されたキーワードを全件取得
3. 各キーワードを Brave Search API で検索
4. Claude が結果をメール本文としてまとめる
5. SES で登録されたメールアドレスに送信
