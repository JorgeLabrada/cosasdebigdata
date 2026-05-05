# Support Ticket Classifier Pipeline

An automated support ticket triage system built with AWS Step Functions, AWS Lambda, and OpenTofu. The pipeline validates incoming support tickets, classifies their severity, stores them in the correct S3 prefix, and signals the final routing outcome through dedicated Step Function states.

## What the pipeline does

When a support ticket arrives (JSON payload with `ticket_id`, `customer`, `priority_score`, and `description`), it travels through three Lambda functions orchestrated by a Step Function state machine:

**Lambda 1 — Validate:** Checks that `priority_score` is a number between 0 and 100 and that `description` is not empty. If either check fails the execution transitions immediately to a `Fail` state (`ValidationFailed`), preventing bad data from propagating downstream. On success the event is returned with a `validated: true` flag added.

**Lambda 2 — Classify:** Determines the ticket's severity (`urgent`, `normal`, or `low`) by combining two signals: the numeric `priority_score` (≥ 75 → urgent, ≥ 40 → normal, < 40 → low) and keyword matching against the `description` (words such as *urgent*, *down*, *unresponsive*, *critical*, or *outage* can escalate the base severity by one level). The result is stored in the `severity` field and returned as part of the event.

**Lambda 3 — Route:** Writes the enriched ticket JSON to S3 under the path `s3://<bucket>/<severity>/<ticket_id>.json`. This makes it trivial to query all urgent tickets, run cost analytics by tier, or hook a downstream consumer onto a specific prefix.

**Choice state — CheckSeverity:** Reads `$.severity` and routes to `UrgentRouted` (Succeed) for urgent tickets or `TicketRouted` (Succeed) for normal and low tickets, giving operators a clear signal in CloudWatch and the Step Functions console.

## State machine summary (7 states, max allowed)

| # | State | Type |
|---|-------|------|
| 1 | ValidateTicket | Task |
| 2 | ClassifyTicket | Task |
| 3 | RouteTicket | Task |
| 4 | CheckSeverity | Choice (3 branches) |
| 5 | UrgentRouted | Succeed |
| 6 | TicketRouted | Succeed |
| 7 | ValidationFailed | Fail |

## Sample input

```json
{
  "ticket_id": "tk-042",
  "customer": "student@uag.mx",
  "priority_score": 85,
  "description": "The system has been unresponsive for 2 hours, this is urgent"
}
```

## Deployment

```bash
tofu init
tofu apply          # deploys everything
tofu destroy        # tears down everything
```

No console clicks. No manual AWS CLI resource creation.

## CI/CD

A GitHub Actions workflow (`.github/workflows/deploy.yml`) runs `tofu validate` and `tofu plan` on every pull request, and `tofu apply` automatically on every push to `main`. Configure `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as repository secrets, and optionally protect the `production` environment in GitHub settings to require manual approval before apply.

## Requirements

- OpenTofu ≥ 1.6
- AWS credentials with permissions for Lambda, Step Functions, S3, and IAM
- Python 3.11 (Lambda runtime, no extra dependencies)
