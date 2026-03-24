# Escalation Guidance by Issue Type

## Purpose
Define clear, role-specific escalation paths and severity triggers for integration issues.

## Severity model
- **SEV-1:** Production-wide outage, security/auth lockout, or high duplicate-risk event.
- **SEV-2:** Major degradation in one or more orgs, replay backlog breaching SLA.
- **SEV-3:** Isolated request-type or transaction issues with workaround.
- **SEV-4:** Documentation/config hygiene issues with no active business impact.

## Escalation matrix

| Issue Type | Typical Signals | Initial Owner | Escalate To | Target Severity |
| --- | --- | --- | --- | --- |
| Security/Auth | `AUTH_FAILURE`, repeated 401/403 | ISS Support Analyst | Salesforce Admin + Credential Owner + Security Ops | SEV-1/2 |
| Endpoint/Config | `MISSING_ENDPOINT_CONFIG`, `ORG_CONFIG_MISSING`, `REQUEST_TYPE_MISSING` | Salesforce Admin | ISS Manager + Application Owner | SEV-2/3 |
| Functional validation | `FUNCTIONAL_FAILURE`, pre-transport validation codes | Salesforce Admin + ISS Analyst | Integration Support Engineer | SEV-3 |
| Transport instability | `RETRYABLE_HTTP_FAILURE`, `CALLOUT_TIMEOUT`, 5xx trend | Integration Support Engineer | ISS Manager + ServiceNow integration owner | SEV-1/2 |
| Platform/unknown | `UNHANDLED_EXCEPTION`, recurring `Unknown` category | Integration Support Engineer | Technical Architect/Application Owner | SEV-2/3 |
| Replay control failure | `REPLAY_NOT_ALLOWED`, abandoned backlog growth | ISS Support Analyst | Integration Support Engineer + Architect | SEV-2/3 |

## Escalation triggers and thresholds

### Immediate escalation (no waiting)
- Any `Security` category failure in production affecting active traffic.
- Evidence of potential duplicate incident creation at scale.
- Multi-org outage pattern in transport or endpoint resolution.

### Escalate within 30 minutes
- Retry backlog still growing after initial mitigation.
- Same error code impacting >10 transactions across >1 org.
- Request type activation/deactivation produced unexpected failures.

### Escalate within 4 business hours
- Repeated single-org configuration errors despite metadata fixes.
- Unknown-category failures that cannot be reproduced in lower environment.

## Role handoff expectations

### ISS Support Analyst → Salesforce Admin
Must include:
- Transaction IDs, correlation IDs, org/request type scope, observed error codes.

### Salesforce Admin → Integration Support Engineer
Must include:
- Metadata diff summary, validation results, and test replay outcomes.

### Integration Support Engineer → Architect/Application Owner
Must include:
- Blast radius, root-cause hypothesis, mitigation options, and risk trade-offs.

## Verification to close escalation
- Error rate returns to baseline.
- New smoke transaction succeeds in affected scope.
- Replay backlog reduced to operational threshold.
- Incident notes include final root cause and preventive actions.
