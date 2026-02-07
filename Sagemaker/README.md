# AWS SageMaker - Nikkei 225 時系列予測モデル

このプロジェクトは、AWS SageMaker を使用して日経平均株価（Nikkei 225）の時系列予測を行うための Terraform インフラストラクチャです。

## 概要

DeepARアルゴリズムを用いて、過去の株価データから将来の株価を予測します。このインフラストラクチャは、データの準備から学習、モデルデプロイまでの全てを自動化します。

## リソース構成の要約

### 1. **IAM ロール・ポリシー**
- **aws_iam_role: `sagemaker_role`**
  - Notebook インスタンス、学習ジョブ、推論エンドポイントが使用する実行ロール
  - S3、ECR、CloudWatch ログへのアクセス権限を付与
  
- **aws_iam_policy: `sagemaker_policy`**
  - S3（データ読み込み・モデル保存）
  - ECR（Docker イメージ取得）
  - CloudWatch ログ（実行ログ記録）
  - IAM（ロール引き受け権限）

### 2. **Notebook インスタンス**
- **aws_sagemaker_notebook_instance: `deepar_notebook`**
  - JupyterLab 環境を提供
  - インスタンスタイプ: ml.t3.medium
  - **用途**: 学習・推論を手動で実行

### 3. **モデル**
- **aws_sagemaker_model: `deepar_model`**
  - 学習済みモデルをモデルレジストリに登録
  - **注**: model_data_url を Notebook で学習完了後に更新

### 4. **エンドポイント設定**
- **aws_sagemaker_endpoint_configuration: `deepar_endpoint_config`**
  - モデルをデプロイするための設定
  - インスタンスタイプ: ml.m5.large
  - インスタンス数: 1

### 5. **推論エンドポイント**
- **aws_sagemaker_endpoint: `deepar_endpoint`**
  - 学習済みモデルを REST API として提供

## リソース関連図

```
┌─────────────────────────────────────────────────────────┐
│               AWS SageMaker インフラ構成                 │
└─────────────────────────────────────────────────────────┘

  S3 バケット（トレーニングデータ）
         ↓
  Terraform (terraform apply)
    ├─ IAM ロール・ポリシー作成
    ├─ SageMaker Notebook インスタンス作成
    └─ AWS CLI で学習ジョブ実行
         │
         ├─→ local-exec: create_training_job.sh
         │   └─→ aws sagemaker create-training-job
         │
         ↓
  SageMaker 学習ジョブ（DeepAR）
    role: sagemaker_role
    params: time_freq=D, prediction_length=7...
         ↓
  S3（学習済みモデル保存）
    model.tar.gz
         ↓
  SageMaker Notebook インスタンス
    (ml.t3.medium)
    Jupyter 環境で対話的に実行
         ↓
  SageMaker モデル登録
    model_data_url: s3://.../output/<JOB-NAME>/output/model.tar.gz
         ↓
  SageMaker エンドポイント設定
    ml.m5.large × 1
         ↓
  SageMaker 推論エンドポイント
    name: nikkei-deepar-endpoint
         ↓
  REST API（推論呼び出し）
```

## データフロー

1. **データ準備フェーズ**
   - CSV 形式の株価データ → JSON 形式に変換
   - S3 にアップロード

2. **インフラ構築フェーズ**
   - `terraform apply` を実行
   - IAM ロール・ポリシー、Notebook インスタンスを作成

3. **学習フェーズ（Notebook で手動実行）**
   - Notebook インスタンスにアクセス
   - `nikkei_prediction.ipynb` を使用してモデルを学習
   - CloudWatch Logs で進行状況を監視

4. **モデル・エンドポイント登録フェーズ**
   - 学習完了を確認
   - `sagemaker.tf` の `model_data_url` を実際の S3 パスに更新
   - `terraform apply` でモデルとエンドポイントを作成

5. **推論フェーズ（Notebook で手動実行）**
   - Notebook インスタンスで推論コードを実行
   - エンドポイントで推論実行

## 出力値

Terraform 実行後、以下の出力値が提供されます：

| 出力値 | 説明 |
|--------|------|
| `sagemaker_notebook_instance_name` | Notebook インスタンス名 |
| `sagemaker_notebook_instance_url` | Notebook インスタンスへのアクセス URL |
| `sagemaker_model_name` | モデル登録名 |
| `sagemaker_endpoint_name` | 推論エンドポイント名 |
| `sagemaker_role_arn` | SageMaker 実行ロール ARN |
| `s3_training_data_location` | トレーニングデータのS3パス |
| `s3_output_path` | モデル出力のS3パス |

## 使用方法

### 前提条件

- AWS アカウントを保有
- Terraform >= 1.6.0 がインストール
- AWS CLI が認証済みで設定済み
- S3 にトレーニングデータ（JSON 形式）が配置済み

### デプロイ手順

```bash
# terraform_code ディレクトリに移動
cd Sagemaker/terraform_code

# 初期化
terraform init

# 計画確認
terraform plan

# デプロイ実行
terraform apply
```

## 使用手順（詳細）

### ステップ1: データの準備
Notebook インスタンスで CSV を JSON 形式に変換して S3 にアップロード：
- `Sagemaker/code/nikkei_prediction.ipynb` を実行

### ステップ2: Terraform でインフラを構築
```bash
cd Sagemaker/terraform_code

# 初期化
terraform init

# 計画確認
terraform plan

# インフラ構築（IAM ロール・ポリシー、Notebook インスタンス）
terraform apply
```

### ステップ3: Notebook インスタンスにアクセス
```bash
# 出力値から Notebook URL を取得
terraform output notebook_instance_url

# ブラウザでアクセスして JupyterLab を開く
```

### ステップ4: Notebook で学習を実行
1. `Sagemaker/code/nikkei_prediction.ipynb` を Notebook インスタンスにアップロード
2. ノートブックを実行して DeepAR モデルを学習
3. CloudWatch Logs で進行状況を確認

### ステップ5: 学習完了後、モデルをデプロイ
学習完了後、以下の手順でモデルを登録・デプロイ：

1. S3 に保存されたモデルの実際のパスを確認：
```
s3://sagemaker-20260207/nikkei-deepar/output/<model-artifact-folder>/model.tar.gz
```

2. `sagemaker.tf` の `model_data_url` を更新：
```hcl
model_data_url = "s3://sagemaker-20260207/nikkei-deepar/output/<model-artifact-folder>/model.tar.gz"
```

3. Terraform でモデルとエンドポイントをデプロイ：
```bash
terraform apply
```

### ステップ6: Notebook で推論を実行
エンドポイント作成後、Notebook インスタンスで推論コードを実行：
- `Sagemaker/code/nikkei_prediction_inference.ipynb` を使用
- または Python スクリプトで直接エンドポイントに推論リクエストを送信

## 注意事項

### S3 バケット・パスの確認
- `s3_bucket = "sagemaker-20260207"`
- `training_data_uri = "s3://sagemaker-20260207/nikkei-deepar/train"`
- `output_path = "s3://sagemaker-20260207/nikkei-deepar/output"`

環境に合わせて、**sagemaker.tf 内のバケット名を調整してください**。

### learning job 完了までの待機時間
- 学習時間は約 **5～10分** 程度です
- CloudWatch ログで進捗を確認できます

### コスト管理
- **学習実行時**: ml.m5.large インスタンスの実行コスト
- **推論エンドポイント実行時**: ml.m5.large インスタンスの継続実行コスト
  - エンドポイントを使用しない場合は、必ずデプロイを削除してください

### ベストプラクティス
1. **本番環境では IAM ポリシーを最小権限に制限**
   - 現在の `AmazonSageMakerFullAccess` は開発環境向け
   
2. **複数インスタンス でのスケーリング**
   - 本番環境では `initial_instance_count` を増やすことを推奨
   
3. **モデルのバージョン管理**
   - 同じモデル名では上書きされるため、タイムスタンプを含めて管理
   
4. **CloudWatch ログの監視**
   - 学習・推論のログは CloudWatch Logs に記録されます

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| S3 アクセスエラー | S3 パスが間違っている | sagemaker.tf の S3 パスを確認・修正 |
| モデル学習失敗 | トレーニングデータフォーマットが不正 | JSON フォーマットを確認 |
| エンドポイトデプロイ失敗 | IAM 権限不足 | IAM ロールの権限を確認 |

## ファイル構成

```
Sagemaker/
├── README.md                    # このファイル
├── terraform_code/
│   ├── provider.tf             # AWS プロバイダー設定
│   ├── sagemaker.tf            # SageMaker リソース定義
│   ├── create_training_job.sh   # 学習ジョブ実行スクリプト（AWS CLI）
│   └── .gitignore              # Git 除外設定
├── code/
│   ├── nikkei_prediction.ipynb           # 学習用ノートブック
│   ├── nikkei_prediction_inference.ipynb # 推論用ノートブック
│   └── predict_result.ipynb              # 結果分析用ノートブック
├── data/
│   ├── nikkei.csv              # 株価データ
│   └── nikkei-2.csv            # 追加データ
└── model/
    ├── model_algo-1-0000.params   # モデルパラメータ
    ├── model_algo-1-config.json   # モデル設定
    └── model_algo-1-symbol.json   # モデルシンボル
```

## 参考リンク

- [AWS SageMaker ドキュメント](https://docs.aws.amazon.com/sagemaker/)
- [DeepAR アルゴリズム](https://docs.aws.amazon.com/sagemaker/latest/dg/deepar.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**最終更新**: 2026年2月7日  
**プロジェクト**: Nikkei 225 時系列予測（SageMaker + Terraform）
