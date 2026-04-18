import json
import boto3

def lambda_handler(event, context):
    client = boto3.client(
        service_name='bedrock-runtime'
    )

    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "system": "あなたは親切なアシスタントです。日本語で回答してください。",  # システムプロンプト
        "messages": [
            {
                "role": "user",
                "content": event.get("prompt", "こんにちは！")
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
        "body": json.dumps({
            "response": output_text
        }, ensure_ascii=False)
    }