import os
import json
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path


def _load_root_env() -> None:
    """リポジトリのルート直下にある .env を探して環境変数に読み込む"""
    for parent in Path(__file__).resolve().parents:
        env_path = parent / ".env"
        if env_path.is_file():
            for line in env_path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))
            break


_load_root_env()

GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")
GOOGLE_CSE_ID = os.environ.get("GOOGLE_CSE_ID") or os.environ.get("GOOGLE_CUSTOM_SEARCH_ENGINE_ID")


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

if __name__ == "__main__":
    query = "Create a model response"
    result = google_custom_search(query)
    print(json.dumps(result, ensure_ascii=False, indent=2))