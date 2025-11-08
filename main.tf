provider "aws" {
  region = "us-east-1"
}

######################
# S3 Buckets
######################
resource "aws_s3_bucket" "source_bucket" {
  bucket = "your-blog-assets"
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = "your-blog-public-assets"
}

######################
# IAM Role e Policy
######################
resource "aws_iam_role" "lambda_role" {
  name = "image-processor-lambda-role"

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

# Permissões para S3 e CloudWatch
resource "aws_iam_role_policy" "lambda_policy" {
  name = "image-processor-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.source_bucket.arn}/*",
          "${aws_s3_bucket.destination_bucket.arn}/*"
        ]
      }
    ]
  })
}

######################
# Lambda Function
######################
resource "aws_lambda_function" "image_processor" {
  function_name = "image-resizer-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  # Caminho para o arquivo zip do código da lambda
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      DESTINATION_BUCKET = aws_s3_bucket.destination_bucket.bucket
    }
  }

  timeout = 30
  memory_size = 512
}

######################
# Permissão do S3 para invocar Lambda
######################
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_bucket.arn
}

######################
# Trigger do S3
######################
resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.source_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}