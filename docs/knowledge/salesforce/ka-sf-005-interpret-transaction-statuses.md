# KA-SF-005 Interpret Transaction Statuses

## Purpose
Standardize how support teams interpret integration transaction status values and expected actions.

## Audience
Salesforce support analysts, integration operators, and incident coordinators.

## Scope
Status interpretation for transaction lifecycle, including operational next steps.

## Source of Truth
- [Observability Model](../../runbooks/observability-model.md)
- [Failure Category Reference](../../troubleshooting/failure-category-reference.md)
- [Integration Support Runbook](../../runbooks/integration-support-runbook.md)

## Status Quick Reference
- **Queued / Pending:** Awaiting async execution; monitor unless SLA threshold exceeded.
- **In Progress:** Active processing; avoid duplicate retries.
- **Succeeded:** Sync completed; verify downstream incident linkage when needed.
- **Failed (Retryable):** Remediate dependency/config issue, then replay per runbook.
- **Failed (Non-Retryable):** Correct source data or mapping first; replay is blocked until fixed.
- **Abandoned / Max Retries:** Escalate for manual intervention and root-cause review.

## Operator Notes
- Always pair status with error code and correlation ID.
- Status alone is not sufficient for escalation priority.

## Escalate When
- Transactions remain pending beyond defined SLA window.
- Repeated retryable failures indicate unresolved systemic issue.
