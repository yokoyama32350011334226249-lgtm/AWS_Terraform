# Bedrock ディレクトリの説明

このファイルは Bedrock フォルダ内にある Terraform と Lambda 関連ファイルの役割と使い方をまとめた説明書です。各ファイルの簡単な説明、主要な変数、注意点を記載しています。

---

## 構成
S3→API Gateway→Lambda→Bedrockの順にアクセスします。
S3のサイトで、プロンプトに対するBedrockの応答を返します。

## ファイル一覧と説明

- api_gateway.tf
  - AWS API Gateway のリソース、メソッド、ステージなどを定義する Terraform ファイルです。
  - 主な役割: Lambda と統合する HTTP エンドポイントの作成、ステージングやデプロイの設定。
  - 注意点: API Gateway の設定変更はデプロイ時にダウンタイムやエンドポイントの変更を引き起こす可能性があります。
  - プリフライトリクエストのためにOPTIONSメソッドを追加しています。

- lambda.tf
  - Lambda 関数の作成、IAM ロール・ポリシー、環境変数、トリガー（API Gateway からの呼び出しや S3 イベントなど）を定義する Terraform ファイルです。
  - 主な役割: lambda_function.zip をアップロードして Lambda を作成・更新する。
  - 重要変数: 関数名、ハンドラー、ランタイム、タイムアウト、メモリサイズ、IAM ロール参照など。

- lambda_function.py
  - Lambda 関数の Python ソースコードです。Bedrock（または外部サービス）へのリクエストを行い、レスポンスを整形して返すロジックが含まれています。
  - 使用方法: デプロイ前に必要なライブラリをパッケージ化して lambda_function.zip に含める必要があります（requirements.txt がある場合はそれに従う）。
  - 注意点: 外部 API キーや認証情報をハードコードしないでください。環境変数や Secrets Manager を利用してください。
  - Bedrockのモデルは申請が不要なtitanにしました。

- lambda_function.zip
  - lambda_function.py と依存ライブラリをまとめたデプロイ用 ZIP アーカイブです。Terraform の aws_lambda_function リソースから参照されます。
  - 更新方法: ソースを修正したら再度 zip を作成し、Terraform 実行時にアップロードされるようにしてください。

- s3.tf
  - S3 バケットやバケットポリシー、オブジェクトの配置に関する Terraform 定義を含みます。
  - 主な役割: 静的ウェブサイトホスティング用のバケットや Lambda のデプロイ用アーティファクト格納など。
  - 注意点: バケットの公開設定や CORS 設定はセキュリティに影響するため適切に設定してください。

- terraform.tfvars.sample
  - terraform.tfvars のサンプルファイルです。実際の環境固有の値（リージョン、アカウントID、S3 バケット名、API 名など）を設定するためのテンプレートとして使います。
  - 使用方法: コピーして terraform.tfvars を作成し、環境に合わせて値を設定してください。機密情報は含めないか、別途管理してください。

- variables.tf
  - Bedrock フォルダ内で使われる Terraform 変数を宣言するファイルです。default 値や型、説明が定義されています。
  - 主な変数: aws_region、environment、lambda_function_name、s3_bucket_name など（ファイル内の具体的な変数を参照してください）。

- website/ (ディレクトリ)
  - 静的ウェブサイトのコンテンツを格納するためのディレクトリです。必要に応じて index.html や CSS/JS ファイルを配置し、S3 と CloudFront で配信する構成を想定しています。


## 注意事項

- 機密情報（API キー、パスワード等）は terraform.tfvars やコードに直接書かず、AWS Secrets Manager や SSM パラメータストア、環境変数で管理してください。
- IAM ポリシーは最小権限の原則に従って設定してください。
- 本リポジトリのブランチ戦略や CI/CD の仕組みに合わせてデプロイ方法を調整してください。

---

この README.md を編集して、より詳細な手順や運用ルール、ファイル間の依存関係を追記してください。
```
