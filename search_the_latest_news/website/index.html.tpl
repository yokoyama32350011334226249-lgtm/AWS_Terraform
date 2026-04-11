<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8" />
    <title>Bedrock Chat</title>
    <style>
        body {
            font-family: sans-serif;
            margin: 40px;
            max-width: 800px;
        }
        textarea {
            width: 100%;
            padding: 10px;
            font-size: 16px;
        }
        button {
            margin-top: 10px;
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
        }
        #response {
            margin-top: 20px;
            white-space: pre-wrap;
            padding: 15px;
            background: #f3f3f3;
            border-radius: 8px;
        }
    </style>
</head>
<body>

<h1>Bedrock に問い合わせ</h1>

<p>下のテキストボックスに問い合わせ内容を入力して、送信ボタンを押してください。</p>

<textarea id="query" rows="6" placeholder="例：要約してください..."></textarea>

<br />
<button onclick="sendText()">送信</button>

<div id="response"></div>

<script>
// ======= API Gateway のエンドポイントを設定 ========
// Terraform apply 後に表示される endpoint を貼り付けてください。
const API_ENDPOINT = "${api_endpoint}/bedrock";

async function sendText() {
    const input = document.getElementById("query").value;
    if (!input) {
        alert("入力してください！");
        return;
    }

    document.getElementById("response").textContent = "問い合わせ中...";

    try {
        const res = await fetch(API_ENDPOINT, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ text: input })
        });

        const data = await res.json();

        document.getElementById("response").textContent =
            data.response || "No response received.";

    } catch (error) {
        console.error(error);
        document.getElementById("response").textContent = "エラーが発生しました。";
    }
}
</script>

</body>
</html>
