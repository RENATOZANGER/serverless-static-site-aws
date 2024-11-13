data "aws_caller_identity" "current" {}

#Using archive_file resource to create lambda_function zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda_function.zip"
}

#Bucket to store the python code
resource "aws_s3_bucket" "lambda_src" {
  bucket = "lambda-src-${data.aws_caller_identity.current.account_id}"
}

#Upload the .zip file to the bucket
resource "aws_s3_object" "upload_zip" {
  bucket = aws_s3_bucket.lambda_src.bucket
  key    = "lambda_function.zip"
  source = "../infra/lambda_function.zip"
  acl    = "private"
}

#Bucket to store the front end
resource "aws_s3_bucket" "static_site" {
  bucket = "static-site-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.static_site.id
  index_document {
    suffix = "index.html"
  }
}

#Configure bucket policy to only allow access to cloudfront
resource "aws_s3_bucket_policy" "static_site_policy" {
  depends_on = [aws_cloudfront_distribution.s3_distribution]
  bucket     = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

#Send the index.html file to bucket
resource "aws_s3_object" "upload_index" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "index.html"
  source = "../static/index.html"
  acl    = "private"

  content_type = "text/html"
  metadata = {
    "description" = "HTML file"
  }
}

#Send some variables to the java script
data "template_file" "scripts_js" {
  template = file("../static/scripts.js.tpl")
  vars = {
    api_url      = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.region}.amazonaws.com",
    api_resource = var.api_resource,
    stage_name   = var.stage_name,
    api_key      = aws_api_gateway_api_key.my_api_key.value
  }
}

#Send the scripts.js file to bucket
resource "aws_s3_object" "upload_scripts" {
  bucket  = aws_s3_bucket.static_site.bucket
  key     = "scripts.js"
  content = data.template_file.scripts_js.rendered
  acl     = "private"

  content_type = "application/javascript"
  metadata = {
    "description" = "JavaScript File"
  }
}
