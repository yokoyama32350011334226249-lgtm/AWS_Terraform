# ===== DynamoDB テーブル（監視アイテム管理） =====
# 目的: ユーザーが登録した「定期検索したいキーワード」と「通知先メールアドレス」を保管する

resource "aws_dynamodb_table" "watch_items" {
  name         = "news-watch-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "item_id"

  attribute {
    name = "item_id"
    type = "S"
  }

  tags = {
    Project = "news-search"
  }
}
