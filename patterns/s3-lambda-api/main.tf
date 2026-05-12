resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "example-workload-${var.environment}-artifacts-"
}

resource "aws_iam_role" "lambda" {
  name = "example-workload-${var.environment}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "handler" {
  type        = "zip"
  output_path = "${path.module}/handler.zip"

  source {
    content  = "def handler(event, context):\n    return {'statusCode': 200, 'body': 'ok'}\n"
    filename = "handler.py"
  }
}

resource "aws_lambda_function" "api" {
  function_name    = "example-workload-${var.environment}"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.11"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
}
