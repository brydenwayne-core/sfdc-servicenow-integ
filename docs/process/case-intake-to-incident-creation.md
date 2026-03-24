# Process Flow: Case Intake to Incident Creation

## Purpose
Document the formal business and technical flow for creating a ServiceNow incident from Salesforce Case intake.

## Business Flow

1. Agent creates or updates a Case requiring external incident handling.
2. Business policy determines request type and processing eligibility.
3. Integration creates/updates corresponding ServiceNow incident.
4. Support teams track outcome through integration telemetry.

## Technical Flow

1. Case event enters intake/orchestration layer.
2. Org/request metadata is resolved.
3. Field mapping and template composition build payload.
4. Routing rules resolve assignment target.
5. Callout to ServiceNow Incident API executes.
6. Response updates link + transaction status.

## Exception Paths

- Missing metadata (org/request/routing/mapping).
- Validation failure due to missing Case data.
- Transport/auth failure with ServiceNow endpoint.

## Retry/Reprocessing Hooks

- Retry path for transient transport failures.
- Replay path for operator-approved eligible transactions.

## Controls and Evidence

- Correlation ID and idempotency key must be present.
- Failure class and error category must be populated on failed transactions.

## Cross-links

- [Logical Architecture](../architecture/logical-architecture.md)
- [Metadata Architecture](../architecture/metadata-architecture.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Replay and Reprocessing Flow](replay-and-reprocessing.md)
