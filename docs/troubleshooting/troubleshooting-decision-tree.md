# Troubleshooting Decision Tree

## Purpose
Provide a deterministic triage workflow by role for incident-support execution.

## Inputs required before starting
- Salesforce Case ID
- `Integration_Transaction__c` record ID
- `CorrelationId__c`
- `Status__c`, `ErrorCategory__c`, `ErrorCode__c`, `RetryCount__c`
- Presence/absence of `ServiceNow_Incident_Link__c`

## Text decision tree

```text
START
  |
  +--> Is transaction present?
  |       |-- No --> Admin: verify orchestration trigger and feature toggle -> escalate to integration engineer if missing trigger path
  |       '-- Yes
  |
  +--> Status = Succeeded?
  |       |-- Yes --> Verify ServiceNow link and close support case
  |       '-- No
  |
  +--> Status in {Queued, In Progress} longer than SLA?
  |       |-- No --> Continue monitoring
  |       '-- Yes --> Check async backlog + transport health; escalate to integration support engineer
  |
  +--> ErrorCategory = Security OR ErrorCode = AUTH_FAILURE?
  |       |-- Yes --> STOP retries; escalate to credential owner + ISS manager
  |       '-- No
  |
  +--> ErrorCategory = Configuration?
  |       |-- Yes --> Validate CMT chain (org->endpoint->request type->template->routing->mapping->toggle)
  |       |            if unresolved, escalate to Salesforce admin/application owner
  |       '-- No
  |
  +--> ErrorCategory = Validation?
  |       |-- Yes --> Determine source-data vs mapping issue
  |       |            fix issue, then replay if eligible
  |       '-- No
  |
  +--> ErrorCategory = Transport OR retryable code?
  |       |-- Yes --> Check duplicate risk (incident link + ServiceNow search by correlation)
  |       |            if safe, replay eligible records; else escalate
  |       '-- No
  |
  +--> ErrorCategory = Platform/Unknown
          |-- Gather diagnostics package and escalate to integration engineering + architect
```

## Role-based execution workflow

### Workflow A — Salesforce Admin (config-heavy incidents)
1. Validate active org/request-type/template/endpoint metadata.
2. Confirm feature toggle and kill switch state.
3. Resolve metadata drift and redeploy if needed.
4. Execute one controlled replay for verification.
5. Update support notes with exact metadata change set.

### Workflow B — ISS Support Analyst (front-line triage)
1. Confirm scope (single case vs multi-org pattern).
2. Classify by `ErrorCategory__c` and `ErrorCode__c`.
3. Apply runbook play: monitor, replay-safe action, or immediate escalation.
4. Route to owner group with required context package.

### Workflow C — Integration Support Engineer (systemic incidents)
1. Quantify failure rate by category and org.
2. Validate transport, queueing, and idempotency behavior.
3. Execute constrained replay batches post-fix.
4. Propose remediation and resilience improvements.

### Workflow D — Technical Architect/Application Owner
1. Decide emergency containment (kill switch, request-type pause, rollout stop).
2. Approve risk-based remediation path and timeline.
3. Coordinate cross-team communication and post-incident actions.

## Minimum escalation package
- 3 sample transaction IDs (or all impacted if smaller)
- Correlation IDs and timestamps (UTC)
- Error code/category distribution
- Retry/backlog state
- Metadata changes deployed in last release window
