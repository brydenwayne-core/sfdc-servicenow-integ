# Process Flow: Failure Classification and Triage

## Purpose
Define standardized triage flow for failed or degraded transactions.

## Failure Classification Model

- **Configuration:** missing/inactive metadata dependencies.
- **Validation:** source data or payload contract errors.
- **Transport:** timeout, throttling, network, downstream 5xx.
- **Security:** authn/authz or credential issues.
- **Unknown:** unhandled/novel failures requiring engineering analysis.

## Triage Workflow

1. Locate transaction by correlation ID and source Case.
2. Confirm status, retry count, failure class, and eligibility.
3. Determine if issue is transient, config-driven, or security-sensitive.
4. Execute runbook action: wait/retry/replay/escalate.
5. Record remediation and open follow-up for repeated class patterns.

## Escalation Criteria

- Security-class failures.
- Repeated failures across multiple orgs/request types.
- Replay backlog above defined operational threshold.

## Metrics

- Time-to-triage (median/P95).
- Recurring failure classes by org/request type.
- Percent of failures resolved without engineering escalation.

## Cross-links

- [Observability Architecture](../architecture/observability-architecture.md)
- [Security Architecture](../architecture/security-architecture.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
