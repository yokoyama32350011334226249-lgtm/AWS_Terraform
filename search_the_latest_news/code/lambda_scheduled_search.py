import json
import os
import urllib.request
import urllib.parse
from datetime import datetime, timezone
import boto3
from boto3.dynamodb.conditions import Attr

BRAVE_API_KEY    = os.environ.get("BRAVE_API_KEY", "")
DYNAMODB_TABLE   = os.environ.get("DYNAMODB_TABLE", "")
SES_SENDER_EMAIL = os.environ.get("SES_SENDER_EMAIL", "")

# Bedrock に登録する Brave Search ツールの定義
TOOLS = [
    {
        "name": "brave_search",
        "description": (
            "Brave Search API を使って最新情報をインターネット検索するツールです。"
            "リアルタイムのニュース、最新情報、または学習データに含まれない情報が必要な場合に使用します。"
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "検索クエリ文字列（日本語・英語どちらでも可）"
                },
                "num": {
                    "type": "integer",
                    "description": "取得する検索結果の件数（1〜20、デフォルト5）",
                    "default": 5
                }
            },
            "required": ["query"]
        }
    }
]


def brave_search(query: str, num: int = 5) -> dict:
    """Brave Search API を呼び出し、検索結果を返す"""
    if not BRAVE_API_KEY:
        return {"error": "BRAVE_API_KEY が設定されていません"}

    num = max(1, min(20, num))
    params = urllib.parse.urlencode({"q": query, "count": num})
    url    = f"https://api.search.brave.com/res/v1/web/search?{params}"

    try:
        req = urllib.request.Request(
            url,
            headers={
                "Accept": "application/json",
                "X-Subscription-Token": BRAVE_API_KEY
            }
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        items = data.get("web", {}).get("results", [])
        results = [
            {
                "title":   item.get("title", ""),
                "link":    item.get("url", ""),
                "snippet": item.get("description", "")
            }
            for item in items
        ]
        return {"results": results, "total": len(results)}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        print(f"❌ Brave Search API Error: {error_body}")
        return {"error": f"Brave Search API エラー: {error_body}"}
    except Exception as e:
        return {"error": f"その他のエラー: {str(e)}"}


def run_tool(tool_name: str, tool_input: dict) -> str:
    """ツール名に応じて対応する関数を実行し、結果を JSON 文字列で返す"""
    if tool_name == "brave_search":
        result = brave_search(
            query=tool_input["query"],
            num=tool_input.get("num", 5)
        )
        return json.dumps(result, ensure_ascii=False)
    return json.dumps({"error": f"未知のツール: {tool_name}"}, ensure_ascii=False)


def invoke_bedrock_with_tools(client, keyword: str) -> str:
    """
    Bedrock (Claude) をツール付きで呼び出し、指定キーワードの最新情報サマリーを返す
    """
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "system": (
            "あなたは最新情報を調べて通知メールを作成する専門アシスタントです。"
            "brave_search ツールを使って指定されたキーワードの最新情報を検索し、"
            "読みやすい日本語のメール本文としてまとめてください。"
            "検索結果の各記事について、タイトル・概要・URLを含めてください。"
        ),
        "tools": TOOLS,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": (
                            f"「{keyword}」に関する最新情報を brave_search で調べて、"
                            "メール通知用にわかりやすく日本語でまとめてください。"
                            "重要なニュースや情報を3〜5件ピックアップしてください。"
                        )
                    }
                ]
            }
        ]
    }

    for _ in range(5):
        response = client.invoke_model(
            modelId="global.anthropic.claude-sonnet-4-6",
            body=json.dumps(request_body),
            contentType="application/json",
            accept="application/json"
        )
        response_body = json.loads(response["body"].read())
        stop_reason   = response_body.get("stop_reason")
        content       = response_body.get("content", [])

        if stop_reason == "tool_use":
            request_body["messages"].append({"role": "assistant", "content": content})
            tool_results = []
            for block in content:
                if block.get("type") == "tool_use":
                    tool_result_content = run_tool(block["name"], block["input"])
                    tool_results.append({
                        "type":        "tool_result",
                        "tool_use_id": block["id"],
                        "content":     tool_result_content
                    })
            request_body["messages"].append({"role": "user", "content": tool_results})

        elif stop_reason == "end_turn":
            for block in content:
                if block.get("type") == "text":
                    return block["text"]
            return ""
        else:
            break

    return "情報の取得に失敗しました。"


def send_email(ses_client, recipient_email: str, keyword: str, summary: str) -> None:
    """SES でメール通知を送信する"""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    ses_client.send_email(
        Source=SES_SENDER_EMAIL,
        Destination={"ToAddresses": [recipient_email]},
        Message={
            "Subject": {
                "Data":    f"【最新情報通知】{keyword} ({today})",
                "Charset": "UTF-8"
            },
            "Body": {
                "Text": {
                    "Data":    summary,
                    "Charset": "UTF-8"
                }
            }
        }
    )


def lambda_handler(event, context):
    """EventBridge から定期実行される検索・通知 Lambda"""
    dynamodb      = boto3.resource("dynamodb")
    table         = dynamodb.Table(DYNAMODB_TABLE)
    bedrock_client = boto3.client("bedrock-runtime")
    ses_client    = boto3.client("ses")

    # enabled = True のアイテムを全件取得
    resp  = table.scan(FilterExpression=Attr("enabled").eq(True))
    items = resp.get("Items", [])

    print(f"[INFO] 処理対象アイテム数: {len(items)}")

    processed = 0
    errors     = 0

    for item in items:
        item_id = item["item_id"]
        keyword = item["keyword"]
        email   = item["email"]

        print(f"[INFO] 検索開始: keyword={keyword}, email={email}")

        try:
            summary = invoke_bedrock_with_tools(bedrock_client, keyword)
            send_email(ses_client, email, keyword, summary)

            # last_searched_at を更新
            table.update_item(
                Key={"item_id": item_id},
                UpdateExpression="SET last_searched_at = :t",
                ExpressionAttributeValues={":t": datetime.now(timezone.utc).isoformat()}
            )
            print(f"[INFO] 通知送信完了: keyword={keyword}")
            processed += 1

        except Exception as e:
            print(f"[ERROR] keyword={keyword}: {str(e)}")
            errors += 1

    return {
        "statusCode": 200,
        "body": json.dumps({
            "processed": processed,
            "errors":    errors,
            "total":     len(items)
        })
    }
