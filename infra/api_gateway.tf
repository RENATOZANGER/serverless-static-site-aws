#Create a REST API in API Gateway called "StudentAPI"
resource "aws_api_gateway_rest_api" "lambda_api" {
  depends_on = [aws_lambda_function.lambda_function]
  name       = "StudentAPI"
}

#Create a new resource within the API
resource "aws_api_gateway_resource" "students" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = var.api_resource
}

#Defining the OPTIONS method
resource "aws_api_gateway_method" "options_students" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.students.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

#Setting the method response to OPTIONS
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = aws_api_gateway_method.options_students.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

#Defining integration for OPTIONS
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = aws_api_gateway_method.options_students.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

#Setting the integration response for OPTIONS
resource "aws_api_gateway_integration_response" "options_integration_response" {
  depends_on  = [aws_api_gateway_integration.options_integration]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = aws_api_gateway_method.options_students.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST,GET'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}


#Defining the POST method
resource "aws_api_gateway_method" "post_students" {
  rest_api_id      = aws_api_gateway_rest_api.lambda_api.id
  resource_id      = aws_api_gateway_resource.students.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true #Defines that the API key is mandatory
}

#Integrating the POST method with the Lambda function
resource "aws_api_gateway_integration" "lambda_integration_POST" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.students.id
  http_method             = aws_api_gateway_method.post_students.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # For integration with Lambda
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_function.arn}/invocations"
}

#Defining the GET method
resource "aws_api_gateway_method" "get_students" {
  rest_api_id      = aws_api_gateway_rest_api.lambda_api.id
  resource_id      = aws_api_gateway_resource.students.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true # Define que a chave de API é obrigatória
}

#Integrating the GET method with the Lambda function
resource "aws_api_gateway_integration" "lambda_integration_GET" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.students.id
  http_method             = aws_api_gateway_method.get_students.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # For integration with Lambda
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_function.arn}/invocations"
}

#Gateway Response configuration for status 429 for java script to get the response
resource "aws_api_gateway_gateway_response" "quota_exceeded_response" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  response_type = "QUOTA_EXCEEDED"
  status_code   = "429"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
    "gatewayresponse.header.Content-Type"                = "'application/json'"
  }

  response_templates = {
    "application/json" = <<EOF
{
    "message": "$context.error.messageString",
    "statusCode": 429,
    "errorType": "$context.error.responseType"
}
EOF
  }
}

#Create the API Gateway deployment for the DEV stage
resource "aws_api_gateway_deployment" "lambda_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration_POST,
    aws_api_gateway_integration.lambda_integration_GET,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  # stage_name  = var.stage_name
}

#Associate Usage Plan with your API
resource "aws_api_gateway_stage" "api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.lambda_api_deployment.id
  lifecycle {
    ignore_changes = [deployment_id]
  }
}

#Create the api key
resource "aws_api_gateway_api_key" "my_api_key" {
  name        = "api_key"
  description = "API key for access control"
  enabled     = true
}

# Creating the Usage Plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on = [aws_api_gateway_stage.api_stage]
  name       = "MyUsagePlan"

  quota_settings {
    limit  = var.limit_quota #Request limit per period
    period = "DAY"           #(DAY, WEEK, MONTH)
  }
  api_stages {
    api_id = aws_api_gateway_rest_api.lambda_api.id
    stage  = aws_api_gateway_stage.api_stage.stage_name
  }
}

#Associating the API key with the usage plan
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
  key_id        = aws_api_gateway_api_key.my_api_key.id
  key_type      = "API_KEY"
}

output "api_key" {
  description = "api_key"
  value       = aws_api_gateway_api_key.my_api_key.value
  sensitive   = true
  #Get key value => terraform output -raw api_key
}
