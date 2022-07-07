# I have created and deployed a serverless application that can perform read and write operation on DynamoDB using a two Lambda functions which are invoked through API gateway call.





resource "aws_dynamodb_table" "ddbtable" {
  name             = "myTable"
  hash_key         = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "id"
    type = "S"
  }
}


resource "aws_iam_role_policy" "write_policy" {
  name = "lambda_write_policy"
  role = aws_iam_role.writeRole.id

  policy = file("./wRole/write_policy.json")
}


resource "aws_iam_role_policy" "read_policy" {
  name = "lambda_read_policy"
  role = aws_iam_role.readRole.id

  policy = file("./rRole/read_policy.json")
}


resource "aws_iam_role" "writeRole" {
  name = "myWriteRole"

  assume_role_policy = file("./wRole/assume_write_role_policy.json")

}


resource "aws_iam_role" "readRole" {
  name = "myReadRole"

  assume_role_policy = file("./rRole/assume_read_role_policy.json")

}


resource "aws_lambda_function" "writeLambda" {

  function_name = "writeLambda"
  s3_bucket     = "mybuck7086125"
  s3_key        = "wterra.zip"
  role          = aws_iam_role.writeRole.arn
  handler       = "wterra.handler"
  runtime       = "nodejs12.x"
}


resource "aws_lambda_function" "readLambda" {

  function_name = "readLambda"
  s3_bucket     = "mybuck7086125"
  s3_key        = "rterra.zip"
  role          = aws_iam_role.readRole.arn
  handler       = "rterra.handler"
  runtime       = "nodejs12.x"
}



resource "aws_api_gateway_rest_api" "apiLambda" {
  name        = "myAPI"

}


resource "aws_api_gateway_resource" "writeResource" {
  rest_api_id = aws_api_gateway_rest_api.apiLambda.id
  parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
  path_part   = "writedb"

}


resource "aws_api_gateway_method" "writeMethod" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.writeResource.id
   http_method   = "POST"
   authorization = "NONE"
}


resource "aws_api_gateway_resource" "readResource" {
  rest_api_id = aws_api_gateway_rest_api.apiLambda.id
  parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
  path_part   = "readdb"

}


resource "aws_api_gateway_method" "readMethod" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.readResource.id
   http_method   = "POST"
   authorization = "NONE"
}




resource "aws_api_gateway_integration" "writeInt" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_resource.writeResource.id
   http_method = aws_api_gateway_method.writeMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.writeLambda.invoke_arn
   
}


resource "aws_api_gateway_integration" "readInt" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_resource.readResource.id
   http_method = aws_api_gateway_method.readMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.readLambda.invoke_arn

}



resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [ aws_api_gateway_integration.writeInt, aws_api_gateway_integration.readInt]

   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   stage_name  = "Prod"
}


resource "aws_lambda_permission" "writePermission" {
   statement_id  = "AllowExecutionFromAPIGateway"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.writeLambda.function_name
   principal     = "apigateway.amazonaws.com"

   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/Prod/POST/writedb"

}


resource "aws_lambda_permission" "readPermission" {
   statement_id  = "AllowExecutionFromAPIGateway"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.readLambda.function_name
   principal     = "apigateway.amazonaws.com"

   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/Prod/POST/readdb"

}


output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}