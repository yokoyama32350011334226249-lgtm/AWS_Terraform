import json
import os
import urllib.request
import urllib.parse
import boto3

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key"
}

# Google Custom Search API の設定（Lambda 環境変数から取得）
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY", "")
GOOGLE_CSE_ID  = os.environ.get("GOOGLE_CSE_ID", "")

# Bedrock に登録する Google Custom Search ツールの定義
TOOLS = [
    {
        "name": "google_custom_search",
        "description": (
            "Google Custom Search API を使って最新情報をインターネット検索するツールです。"
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
                    "description": "取得する検索結果の件数（1〜10、デフォルト5）",
                    "default": 5
                }
            },
            "required": ["query"]
        }
    }
]


def google_custom_search(query: str, num: int = 5) -> dict:
    """Google Custom Search API を呼び出し、検索結果を返す"""
    if not GOOGLE_API_KEY or not GOOGLE_CSE_ID:
        return {"error": "GOOGLE_API_KEY または GOOGLE_CSE_ID が設定されていません"}

    num = max(1, min(10, num))  # 1〜10 の範囲に制限
    params = urllib.parse.urlencode({
        "key": GOOGLE_API_KEY,
        "cx": GOOGLE_CSE_ID,
        "q": query,
        "num": num
        # "lr": "lang_ja"   # 日本語結果を優先
    })
    url = f"https://www.googleapis.com/customsearch/v1?{params}"

    try:
        # req = urllib.request.Request(url, headers={"Accept": "application/json"})
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        items = data.get("items", [])
        results = [
            {
                "title":   item.get("title", ""),
                "link":    item.get("link", ""),
                "snippet": item.get("snippet", "")
            }
            for item in items
        ]
        return {"results": results, "total": data.get("searchInformation", {}).get("totalResults", "0")}
    except urllib.error.HTTPError as e:
        # 💡 ここが肝心！Googleが怒っている本当の理由をログに出力します
        error_body = e.read().decode("utf-8")
        print(f"❌ Google API Error Body: {error_body}")
        return f"Google API側でエラーが発生しました: {error_body}"
    except Exception as e:
        return f"その他のエラー: {str(e)}"

def run_tool(tool_name: str, tool_input: dict) -> str:
    """ツール名に応じて対応する関数を実行し、結果を JSON 文字列で返す"""
    if tool_name == "google_custom_search":
        result = google_custom_search(
            query=tool_input["query"],
            num=tool_input.get("num", 5)
        )
        return json.dumps(result, ensure_ascii=False)
    return json.dumps({"error": f"未知のツール: {tool_name}"}, ensure_ascii=False)


def invoke_bedrock_with_tools(client, messages: list) -> str:
    """
    Bedrock (Claude) をツール付きで呼び出し、ツール使用ループを処理して
    最終的なテキスト応答を返す。
    """
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "system": (
            "あなたは最新情報を調べて回答できる親切なアシスタントです。"
            "ユーザーの質問に答えるために必要であれば google_custom_search ツールを積極的に使用し、"
            "検索結果を踏まえて日本語で回答してください。"
        ),
        "tools": TOOLS,
        "messages": messages
    }

    # ツール使用ループ（最大 5 回まで）
    for _ in range(5):
        response = client.invoke_model(
            modelId="global.anthropic.claude-sonnet-4-6",
            body=json.dumps(request_body),
            contentType="application/json",
            accept="application/json"
        )
        response_body = json.loads(response["body"].read())

        stop_reason = response_body.get("stop_reason")
        content     = response_body.get("content", [])

        # ── ① ツール呼び出しが要求された場合 ────────────────────────────
        if stop_reason == "tool_use":
            # アシスタントの応答をメッセージ履歴に追加
            request_body["messages"].append({
                "role": "assistant",
                "content": content
            })

            # ツールを実行して結果を収集
            tool_results = []
            for block in content:
                if block.get("type") == "tool_use":
                    tool_result_content = run_tool(block["name"], block["input"])
                    tool_results.append({
                        "type":        "tool_result",
                        "tool_use_id": block["id"],
                        "content":     tool_result_content
                    })

            # ツール結果をメッセージ履歴に追加してループを継続
            request_body["messages"].append({
                "role": "user",
                "content": tool_results
            })

        # ── ② 最終回答が返った場合 ────────────────────────────────────────
        elif stop_reason == "end_turn":
            for block in content:
                if block.get("type") == "text":
                    return block["text"]
            return ""

        # ── ③ 予期しない stop_reason ─────────────────────────────────────
        else:
            break

    return "応答の生成に失敗しました。"


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

    messages = body.get("messages", [])
    if not messages:
        return {
            "statusCode": 400,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "messages is required"}, ensure_ascii=False)
        }

    # contentが文字列の場合、Bedrock形式（配列）に変換する
    bedrock_messages = []
    for msg in messages:
        content = msg.get("content", "")
        if isinstance(content, str):
            bedrock_messages.append({
                "role": msg["role"],
                "content": [{"type": "text", "text": content}]
            })
        else:
            bedrock_messages.append(msg)

    # ④ Bedrock をツール付きで呼び出し
    client = boto3.client(service_name="bedrock-runtime")
    output_text = invoke_bedrock_with_tools(client, bedrock_messages)

    return {
        "statusCode": 200,
        "headers": CORS_HEADERS,
        "body": json.dumps({"response": output_text}, ensure_ascii=False)
    }