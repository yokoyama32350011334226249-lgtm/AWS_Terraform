import json
import boto3
import urllib.request
import urllib.parse
import os

SECRET_NAME = os.environ["SECRET_NAME"]

_secret_cache = None

def get_secrets():
    global _secret_cache
    if _secret_cache:
        return _secret_cache
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=SECRET_NAME)
    _secret_cache = json.loads(response["SecretString"])
    return _secret_cache


def lambda_handler(event, context):
    query = event.get("query", "").strip()
    if not query:
        return {"results": [], "error": "query is required"}

    secrets       = get_secrets()
    google_api_key = secrets["GOOGLE_API_KEY"]
    google_cx      = secrets["GOOGLE_CX"]

    params = urllib.parse.urlencode({
        "key": google_api_key,
        "cx":  google_cx,
        "q":   query,
        "num": 5,
    })
    url = f"https://www.googleapis.com/customsearch/v1?{params}"

    try:
        with urllib.request.urlopen(url, timeout=10) as res:
            data = json.loads(res.read())
    except Exception as e:
        return {"results": [], "error": str(e)}

    results = [
        {
            "title":   item.get("title"),
            "link":    item.get("link"),
            "snippet": item.get("snippet"),
        }
        for item in data.get("items", [])
    ]
    return {"results": results}
