"""
===== Lambda 関数：Bedrock AI モデルへのリクエスト処理 =====
このスクリプトは API Gateway からのリクエストを受け取り、
Amazon Bedrock の titan モデルに問い合わせを行い、結果をクライアントに返します。

処理フロー:
  1. API Gateway から JSON リクエストを受信
  2. リクエストボディからユーザーの入力テキストを抽出
  3. Bedrock の titan モデルに入力を送信
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
    user_input = body.get("text", "入力がありません")

    print("User input:", user_input)

    if not user_input:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "query is required"}),
            "headers": {
                "Access-Control-Allow-Origin": "*"
                }
        }

    # ===== Bedrock モデル用ペイロードの構築 =====
    payload = {
        "inputText": user_input,
        "textGenerationConfig": {
            "maxTokenCount": 512,
            "temperature": 0.7,
            "topP": 0.9
        }
    }

    # ===== Bedrock モデル呼び出し =====
    # 目的: Claude AI モデルにユーザーのリクエストを送信して応答を取得
    # 処理:
    #   1. modelId で使用する AI モデルを指定
    #   2. messages でユーザーのメッセージを Claude に送信
    #   3. max_tokens で応答の最大トークン数を制限
    response = client.invoke_model(
        # 使用する AI モデル： amazon.titan-text-express-v1
        modelId="amazon.titan-text-express-v1",
        # リクエストヘッダー：JSON 形式を指定
        contentType="application/json",
        # レスポンスヘッダー：JSON 形式を期待
        accept="application/json",
        # リクエストボディ：JSON 文字列としてペイロードを渡す
        body=json.dumps(payload)
    )

    print("Bedrock response:", response)

    # ===== Bedrock モデルの応答解析 =====
    # 目的: Bedrock からの応答をパースして生成されたテキストを抽出
    body_bytes = response["body"].read() # バイト列として応答ボディを取得
    body_str = body_bytes.decode("utf-8") # バイト列を文字列に変換
    result = json.loads(body_str)         # 文字列を JSON ディクショナリに変換
    output_text = ""
    results = result.get("results", [])
    if results and isinstance(results, list):
        output_text = results[0].get("outputText", "")

    print("文字列変換後：",body_str)
    print("Parsed result:", result)
    print("Output text:", output_text)

    # ===== HTTP レスポンスの組み立て =====
    # 目的: クライアントに HTTP 形式のレスポンスを返す
    # 形式: API Gateway v2 ペイロード形式 2.0（Lambda Proxy 統合）に対応
    return {
        # ステータスコード：200 は正常処理完了
        "statusCode": 200,
        # HTTP ヘッダー： CORS 設定を含む
        "headers": {
            "Access-Control-Allow-Origin": "*",  # 必要なら制限可
        },
        # レスポンスボディ：AI の応答を JSON で返す
        "body": json.dumps({"response": output_text})
    }
