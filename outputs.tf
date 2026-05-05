output "state_machine_arn" {
  value = aws_sfn_state_machine.ticket_pipeline.arn
}

output "state_machine_name" {
  value = aws_sfn_state_machine.ticket_pipeline.name
}

output "tickets_bucket" {
  value = aws_s3_bucket.tickets.bucket
}

output "validate_lambda" {
  value = module.lambda_validate.function_name
}

output "classify_lambda" {
  value = module.lambda_classify.function_name
}

output "route_lambda" {
  value = module.lambda_route.function_name
}
