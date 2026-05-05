resource "aws_sfn_state_machine" "ticket_pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "Support Ticket Classifier Pipeline"
    StartAt = "ValidateTicket"
    States = {
      # ── State 1 ───────────────────────────────────────────────────────────
      ValidateTicket = {
        Type     = "Task"
        Resource = module.lambda_validate.function_arn
        Next     = "ClassifyTicket"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ValidationFailed"
        }]
      }

      # ── State 2 ───────────────────────────────────────────────────────────
      ClassifyTicket = {
        Type     = "Task"
        Resource = module.lambda_classify.function_arn
        Next     = "RouteTicket"
      }

      # ── State 3 ───────────────────────────────────────────────────────────
      RouteTicket = {
        Type     = "Task"
        Resource = module.lambda_route.function_arn
        Next     = "CheckSeverity"
      }

      # ── State 4 ───────────────────────────────────────────────────────────
      CheckSeverity = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.severity"
            StringEquals = "urgent"
            Next         = "UrgentRouted"
          },
          {
            Variable     = "$.severity"
            StringEquals = "normal"
            Next         = "TicketRouted"
          },
          {
            Variable     = "$.severity"
            StringEquals = "low"
            Next         = "TicketRouted"
          },
        ]
        Default = "TicketRouted"
      }

      # ── State 5 ───────────────────────────────────────────────────────────
      UrgentRouted = {
        Type = "Succeed"
      }

      # ── State 6 ───────────────────────────────────────────────────────────
      TicketRouted = {
        Type = "Succeed"
      }

      # ── State 7 ───────────────────────────────────────────────────────────
      ValidationFailed = {
        Type  = "Fail"
        Error = "ValidationError"
        Cause = "mensaje 5"
      }
    }
  })
}
