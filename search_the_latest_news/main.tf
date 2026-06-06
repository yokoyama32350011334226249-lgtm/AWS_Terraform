module "bedrock_lambda_apigw_s3" {
  source = "../Bedrock"
  s3_bucket_name = "news-search-static-site"
  api_name = "news-search-api"
  allowed_ip = var.allowed_ip #S3
  filepath_index_html = "../search_the_latest_news/website/index.html.tmp" #S3
  filepath_lambda_py = "${path.module}/code/lambda_function.py"
  filepath_lambda_zip = "${path.module}/code/lambda_function.zip"
  lambda_function_name = "news-search-lambda"
  lambda_role_name = "news-search-lambda-role"
  google_api_key = var.google_api_key
  google_cse_id  = var.google_cse_id
}