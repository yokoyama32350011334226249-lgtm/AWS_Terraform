"""
===== Lambda 関数：Bedrock AI モデルへのリクエスト処理 =====
このスクリプトは API Gateway からのリクエストを受け取り、
Amazon Bedrock の Claude AI モデルに問い合わせを行い、結果をクライアントに返します。

処理フロー:
  1. API Gateway から JSON リクエストを受信
  2. リクエストボディからユーザーの入力テキストを抽出
  3. Bedrock の Claude モデルに入力を送信
  4. AI が生成した応答を JSON 形式で返却
"""

import json
import boto3

# ===== Bedrock Runtime クライアントの初期化 =====
# 目的: AWS Bedrock サービスと通信するためのクライアントを作成
# 機能: invoke_model メソッドで AI モデルを呼び出す際に使用
client = boto3.client("bedrock-runtime")


def handler(event, context):
    """
    Lambda ハンドラー関数：API Gateway からのリクエストを処理
    
    パラメータ:
        event (dict): API Gateway から渡されるイベントオブジェクト
                      - body: クライアントから送信された JSON リクエスト
        context (dict): Lambda 実行コンテキスト（ここでは使用しない）
    
    戻り値:
        dict: HTTP レスポンス
              - statusCode: HTTP ステータスコード
              - headers: HTTP ヘッダー
              - body: JSON 形式のレスポンスボディ
    """
    
    # ===== リクエストボディのパース =====
    # 目的: API Gateway から送信された JSON データをディクショナリに変換
    # 処理: JSON 形式を期待するが、ない場合は空の JSON {} を使用
    body = json.loads(event.get("body", "{}"))
    
    # ===== ユーザー入力テキストの抽出 =====
    # 目的: リクエストから AI に送信するテキストを取得
    # デフォルト: "こんにちは" - 入力がない場合の初期値
    user_input = body.get("text", "こんにちは")

    # ===== Bedrock モデル呼び出し =====
    # 目的: Claude AI モデルにユーザーのリクエストを送信して応答を取得
    # 処理:
    #   1. modelId で使用する AI モデルを指定
    #   2. messages でユーザーのメッセージを Claude に送信
    #   3. max_tokens で応答の最大トークン数を制限
    response = client.invoke_model(
        # 使用する AI モデル：Claude 3 Haiku（高速・低コスト）
        modelId="anthropic.claude-3-haiku-20240307-v1:0",
        # リクエストボディ：メッセージ形式で AI に送信
        body=json.dumps({
            # メッセージ配列：ユーザーの入力を user ロールで送信
            "messages": [{"role": "user", "content": user_input}],
            # 生成テキストの最大トークン数（長さの制限）
            "max_tokens": 500
        })
    )

    # ===== Bedrock からのレスポンス処理 =====
    # 目的: Bedrock が返したバイナリデータを文字列に変換
    # 処理:
    #   1. response["body"].read() でストリームから全データ読み込み
    #   2. .decode() でバイト列を UTF-8 文字列に変換
    output = response["body"].read().decode()

    # ===== HTTP レスポンスの組み立て =====
    # 目的: クライアントに HTTP 形式のレスポンスを返す
    # 形式: API Gateway v2 ペイロード形式 2.0（Lambda Proxy 統合）に対応
    return {
        # ステータスコード：200 は正常処理完了
        "statusCode": 200,
        # HTTP ヘッダー：JSON 形式であることを示す
        "headers": {"Content-Type": "application/json"},
        # レスポンスボディ：AI の応答を JSON で返す
        "body": json.dumps({"response": output})
    }
