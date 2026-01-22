###############################################################################
# SAM - Lambda: batch transform trigger (manual)
###############################################################################

locals {
  sam_batch_trigger_lambda_name = format(
    "%s-%s-%s-energie-batch-transform-trigger",
    local.entity,
    local.project,
    local.environment
  )
}

data "aws_iam_policy_document" "sam_lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sam_batch_trigger_lambda_role" {
  name               = "${local.sam_batch_trigger_lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.sam_lambda_assume_role.json

  tags = merge(local.xxxx_base_tags, { Name = "${local.sam_batch_trigger_lambda_name}-role" })
}

data "aws_iam_policy_document" "sam_batch_trigger_lambda_policy" {
  # CloudWatch logs (scopé)
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.sam_current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.sam_batch_trigger_lambda_name}:*",
      "arn:aws:logs:${data.aws_region.sam_current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.sam_batch_trigger_lambda_name}:log-stream:*"
    ]
  }

  # Permissions to launch batch transform job
  statement {
    effect = "Allow"
    actions = [
      "sagemaker:CreateTransformJob",
      "sagemaker:DescribeTransformJob",
      "sagemaker:ListTransformJobs"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sam_batch_trigger_lambda_policy" {
  name   = "${local.sam_batch_trigger_lambda_name}-policy"
  policy = data.aws_iam_policy_document.sam_batch_trigger_lambda_policy.json

  tags = merge(local.xxxx_base_tags, { Name = "${local.sam_batch_trigger_lambda_name}-policy" })
}

resource "aws_iam_role_policy_attachment" "sam_batch_trigger_lambda_attach" {
  role       = aws_iam_role.sam_batch_trigger_lambda_role.name
  policy_arn = aws_iam_policy.sam_batch_trigger_lambda_policy.arn
}

resource "aws_lambda_function" "sam_batch_transform_trigger" {
  function_name = local.sam_batch_trigger_lambda_name
  role          = aws_iam_role.sam_batch_trigger_lambda_role.arn

  filename         = var.sam_batch_trigger_lambda_zip_path
  source_code_hash = filebase64sha256(var.sam_batch_trigger_lambda_zip_path)

  handler = var.sam_batch_trigger_lambda_handler
  runtime = var.sam_batch_trigger_lambda_runtime

  timeout     = 60
  memory_size = 512

  environment {
    variables = {
      SAGEMAKER_MODEL_NAME = aws_sagemaker_model.sam_doc_processing_model.name
      RAW_BUCKET           = local.sam_raw_bucket_name
      ENRICHED_BUCKET      = local.sam_enriched_bucket_name
    }
  }

  tags = merge(local.xxxx_base_tags, { Name = local.sam_batch_trigger_lambda_name })
}

output "sam_batch_transform_trigger_lambda_name" {
  value = aws_lambda_function.sam_batch_transform_trigger.function_name
}
