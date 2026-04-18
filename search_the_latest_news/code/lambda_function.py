import json
import boto3

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",#"http://${aws_s3_bucket_website_configuration.website.website_endpoint}",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key"
}

def lambda_handler(event, context):

    # ① OPTIONSリクエスト（CORSプリフライト）の処理
    http_method = event.get("requestContext", {}).get("http", {}).get("method", "")
    if http_method == "OPTIONS":
        return {
            "statusCode": 204,
            "headers": CORS_HEADERS,
            "body": ""
        }

    # ② リクエストボディが空の場合
    body = event.get("body")
    if not body:
        return {
            "statusCode": 400,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "Request body is empty"})
        }

    # ③ bodyをパース
    if isinstance(body, str):
        body = json.loads(body)

    prompt = body.get("prompt")
    if not prompt:
        return {
            "statusCode": 400,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "prompt is required"}, ensure_ascii=False)
        }

    # ④ Bedrockの呼び出し
    client = boto3.client(service_name='bedrock-runtime')

    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "system": "あなたは親切なアシスタントです。日本語で回答してください。",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }

    response = client.invoke_model(
        modelId="global.anthropic.claude-sonnet-4-6",
        body=json.dumps(request_body),
        contentType="application/json",
        accept="application/json"
    )

    response_body = json.loads(response["body"].read())
    output_text = response_body["content"][0]["text"]

    return {
        "statusCode": 200,
        "headers": CORS_HEADERS,
        "body": json.dumps({"response": output_text}, ensure_ascii=False)
    }