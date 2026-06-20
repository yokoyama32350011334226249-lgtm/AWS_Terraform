# ===== SES 送信元メールアドレスの検証 =====
# NOTE: apply 後、指定したメールアドレスに AWS から確認メールが届きます。
#       メール内のリンクをクリックして検証を完了してください。
#       SES サンドボックス環境では、送信先メールアドレスも個別に検証が必要です。
#       本番環境への移行は AWS コンソールの SES > Account dashboard から申請できます。
resource "aws_ses_email_identity" "sender" {
  email = var.ses_sender_email
}
