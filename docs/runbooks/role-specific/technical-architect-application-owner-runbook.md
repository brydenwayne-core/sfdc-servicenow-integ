# Technical Architect / Application Owner Runbook

## Mission
Own service-level risk decisions, architecture guardrails, and long-term reliability outcomes.

## Core responsibilities
- Approve high-risk operational decisions.
- Govern integration design boundaries and metadata standards.
- Coordinate cross-team incident response and communication.
- Ensure post-incident corrective actions are delivered.

## Decision responsibilities during incidents
- Decide on kill switch activation and request-type suspension.
- Approve emergency change windows and rollback plans.
- Prioritize remediation path (hotfix vs metadata rollback vs controlled replay).
- Validate severity classification and stakeholder notifications.

## Governance checkpoints
- Ensure runbooks and troubleshooting docs stay current.
- Ensure production changes are traceable and peer-reviewed.
- Confirm control-plane metrics are monitored and acted upon.
- Verify role ownership remains explicit (no tribal knowledge dependency).

## Post-incident workflow
1. Confirm final root cause statement.
2. Validate short-term containment completed.
3. Assign long-term reliability actions with due dates.
4. Update architecture/process docs where guidance changed.

## Escalation and communication
- Executive updates for SEV-1/SEV-2 incidents.
- External vendor coordination for ServiceNow platform events.
- Security governance coordination for authentication incidents.

## Done criteria
- Service restored and verified.
- Decision log and timeline published.
- Follow-up actions accepted into backlog with ownership.
