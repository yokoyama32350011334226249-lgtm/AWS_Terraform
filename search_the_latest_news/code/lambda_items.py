import json
import os
import uuid
from datetime import datetime, timezone
import boto3

DYNAMODB_TABLE   = os.environ.get("DYNAMODB_TABLE", "")
SES_SENDER_EMAIL = os.environ.get("SES_SENDER_EMAIL", "")

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key"
}


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path   = event.get("rawPath", "")

    # OPTIONSプリフライト
    if method == "OPTIONS":
        return {"statusCode": 204, "headers": CORS_HEADERS, "body": ""}

    dynamodb = boto3.resource("dynamodb")
    table    = dynamodb.Table(DYNAMODB_TABLE)

    # ── GET /items ── アイテム一覧取得
    if method == "GET" and path == "/items":
        resp  = table.scan()
        items = resp.get("Items", [])
        items.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        return {
            "statusCode": 200,
            "headers": CORS_HEADERS,
            "body": json.dumps({"items": items}, ensure_ascii=False, default=str)
        }

    # ── POST /items ── アイテム登録
    if method == "POST" and path == "/items":
        raw_body = event.get("body", "{}")
        body = json.loads(raw_body) if isinstance(raw_body, str) else raw_body

        keyword = body.get("keyword", "").strip()

        if not keyword:
            return {
                "statusCode": 400,
                "headers": CORS_HEADERS,
                "body": json.dumps({"error": "keyword は必須です"}, ensure_ascii=False)
            }

        item = {
            "item_id":    str(uuid.uuid4()),
            "keyword":    keyword,
            "email":      SES_SENDER_EMAIL,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "enabled":    True
        }
        table.put_item(Item=item)

        return {
            "statusCode": 201,
            "headers": CORS_HEADERS,
            "body": json.dumps({"item": item}, ensure_ascii=False)
        }

    # ── DELETE /items/{item_id} ── アイテム削除
    if method == "DELETE" and path.startswith("/items/"):
        item_id = path.split("/items/", 1)[1]
        if not item_id:
            return {
                "statusCode": 400,
                "headers": CORS_HEADERS,
                "body": json.dumps({"error": "item_id が指定されていません"}, ensure_ascii=False)
            }
        table.delete_item(Key={"item_id": item_id})
        return {
            "statusCode": 200,
            "headers": CORS_HEADERS,
            "body": json.dumps({"message": "削除しました"}, ensure_ascii=False)
        }

    return {
        "statusCode": 404,
        "headers": CORS_HEADERS,
        "body": json.dumps({"error": "Not Found"})
    }
