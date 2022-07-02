provider "aws" {
  profile = var.profile
}

resource "aws_lambda_function" "lambda" {
  function_name    = "${var.stack_name}-lambda"
  # uncomment to deploy the lambda without the provided runtime built by GraalVM
#  filename         = "lambda/target/lambda.jar"
#  source_code_hash = filebase64sha256("lambda/target/lambda.jar")
#  runtime          = "java11"
#  handler          = "pkg.Lambda::handleRequest"
  filename         = "lambda/target/lambda.zip"
  source_code_hash = filebase64sha256("lambda/target/lambda.zip")
  runtime          = "provided.al2"
  handler          = "pkg.GraalLambda::handleRequest"
  architectures    = ["x86_64"]
  memory_size      = 512
  timeout          = 30
  role             = aws_iam_role.lambda.arn

  environment {
    variables = {
      # https://aws.amazon.com/blogs/compute/optimizing-aws-lambda-function-performance-for-java/
      JAVA_TOOL_OPTIONS = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    }
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.stack_name}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]
}

resource "aws_sns_topic" "test" {
  name = "${var.stack_name}-test"
}

resource "aws_sqs_queue" "test_to_fn" {
  name = "${var.stack_name}-test-to-fn"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.test_dlq.arn
    maxReceiveCount     = 1
  })
}

resource "aws_sqs_queue_policy" "test_to_fn" {
  queue_url = aws_sqs_queue.test_to_fn.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Resource = aws_sqs_queue.test_to_fn.arn
        Action = [
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:PurgeQueue",
        ]
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.test.arn
          }
        }
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "queue_to_fn" {
  event_source_arn = aws_sqs_queue.test_to_fn.arn
  function_name    = aws_lambda_function.lambda.arn
  batch_size       = 1
}

resource "aws_sns_topic_subscription" "test" {
  topic_arn            = aws_sns_topic.test.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.test_to_fn.arn
  raw_message_delivery = true
}

resource "aws_sqs_queue" "test_dlq" {
  name = "${var.stack_name}-test-dlq"
}

resource "aws_sqs_queue_policy" "test_dlq" {
  queue_url = aws_sqs_queue.test_dlq.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Resource  = aws_sqs_queue.test_dlq.arn
        Action = [
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:PurgeQueue",
        ]
      }
    ]
  })
}
