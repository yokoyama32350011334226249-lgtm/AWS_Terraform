import json
import boto3
import os

CORS_HEADERS = {
    "Access-Control-Allow-Origin":  "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key",
}

BEDROCK_MODEL_ID = os.environ["BEDROCK_MODEL_ID"]
SEARCH_FUNCTION  = os.environ["SEARCH_FUNCTION_NAME"]


def call_bedrock(messages, system_prompt):
    client = boto3.client("bedrock-runtime")
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2048,
        "system": system_prompt,
        "messages": messages,
    }
    response = client.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=json.dumps(request_body),
        contentType="application/json",
        accept="application/json",
    )
    body = json.loads(response["body"].read())
    return body["content"][0]["text"]


def invoke_search_lambda(query):
    client = boto3.client("lambda")
    payload = json.dumps({"query": query})
    response = client.invoke(
        FunctionName=SEARCH_FUNCTION,
        InvocationType="RequestResponse",
        Payload=payload,
    )
    result = json.loads(response["Payload"].read())
    # Search Lambda は {"results": [...]} を返す
    return result.get("results", [])


def lambda_handler(event, context):
    # CORS プリフライト
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "")
    if http_method == "OPTIONS":
        return {"statusCode": 204, "headers": CORS_HEADERS, "body": ""}

    # ボディ取得
    body = event.get("body", "{}")
    if isinstance(body, str):
        body = json.loads(body)

    topic = body.get("topic", "").strip()
    if not topic:
        return {
            "statusCode": 400,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "topic is required"}, ensure_ascii=False),
        }

    # Step1: 検索クエリ生成
    search_query = call_bedrock(
        messages=[{
            "role": "user",
            "content": [{"type": "text", "text":
                f"次のトピックに最適なGoogle検索クエリを1つだけ返してください。"
                f"クエリのみ出力してください。\nトピック: {topic}"
            }],
        }],
        system_prompt="あなたは検索クエリ最適化の専門家です。",
    ).strip()

    # Step2: Google検索を実行（Search Lambda 経由）
    search_results = invoke_search_lambda(search_query)
    results_text = "\n\n".join([
        f"【{r.get('title', '')}】\n{r.get('snippet', '')}\nURL: {r.get('link', '')}"
        for r in search_results
    ])

    # Step3: 検索結果を要約
    summary = call_bedrock(
        messages=[{
            "role": "user",
            "content": [{"type": "text", "text":
                f"以下の検索結果をもとに「{topic}」について"
                f"日本語でわかりやすくまとめてください。\n\n{results_text}"
            }],
        }],
        system_prompt=(
            "あなたは情報収集・要約の専門家です。"
            "検索結果を整理し、読みやすいレポートを作成してください。"
        ),
    )

    return {
        "statusCode": 200,
        "headers": CORS_HEADERS,
        "body": json.dumps({
            "topic":          topic,
            "search_query":   search_query,
            "search_results": search_results,
            "summary":        summary,
        }, ensure_ascii=False),
    }
