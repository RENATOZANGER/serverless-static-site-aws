#Create Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 7
}

#Create Lambda Function
resource "aws_lambda_function" "lambda_function" {
  depends_on    = [aws_s3_object.upload_zip]
  function_name = var.function_name
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      TABLE_NAME       = var.table_name
      REGION_US_EAST_1 = var.region
    }
  }
}

#Allow API Gateway to invoke Lambda function
resource "aws_lambda_permission" "allow_api_gateway" {
  depends_on    = [aws_api_gateway_rest_api.lambda_api]
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}
