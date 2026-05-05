terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "ticket-classifier-tfstate-jorgel"
    key    = "ticket-classifier/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Lambda ZIP archives ────────────────────────────────────────────────────────

data "archive_file" "validate" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/validate"
  output_path = "${path.module}/.terraform/tmp/validate.zip"
}

data "archive_file" "classify" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/classify"
  output_path = "${path.module}/.terraform/tmp/classify.zip"
}

data "archive_file" "route" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/route"
  output_path = "${path.module}/.terraform/tmp/route.zip"
}

# ── Lambda functions ───────────────────────────────────────────────────────────

module "lambda_validate" {
  source           = "./modules/lambda_function"
  function_name    = "${var.project_name}-validate"
  role_arn         = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.validate.output_path
  source_code_hash = data.archive_file.validate.output_base64sha256
}

module "lambda_classify" {
  source           = "./modules/lambda_function"
  function_name    = "${var.project_name}-classify"
  role_arn         = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.classify.output_path
  source_code_hash = data.archive_file.classify.output_base64sha256
}

module "lambda_route" {
  source           = "./modules/lambda_function"
  function_name    = "${var.project_name}-route"
  role_arn         = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.route.output_path
  source_code_hash = data.archive_file.route.output_base64sha256
  environment_variables = {
    BUCKET_NAME = aws_s3_bucket.tickets.bucket
  }
}
