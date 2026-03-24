# Salesforce Admin Runbook

## Mission
Own configuration integrity, safe changes, and first-line metadata remediation.

## Core responsibilities
- Maintain integration Custom Metadata records and lifecycle fields.
- Administer Named Credential/External Credential references.
- Validate request type/routing/field mapping activation.
- Execute controlled post-fix replay in coordination with ISS.

## Daily checklist
1. Review failed transactions by `ErrorCategory__c`.
2. Confirm no newly inactive critical metadata records.
3. Check feature toggle and kill switch states for active orgs.
4. Validate high-priority request types are healthy.

## Standard procedures

### A) Onboard/modify org configuration
- Configure endpoint metadata first.
- Configure org record with default request type.
- Activate templates, request types, routes, and mappings.
- Enable feature toggles by rollout plan.
- Validate with smoke transaction.

### B) Update field mappings safely
- Validate one active mapping per target field per scope.
- Use sequence ordering for deterministic payloads.
- Test with representative case data.
- Document changes in `Admin_Notes__c` and release log.

### C) Handle configuration failures
- Run configuration validation.
- Fix broken references or inactive dependencies.
- Re-test in lower environment when blast radius is unclear.

## Escalation
- Escalate to credential owner for auth/security issues.
- Escalate to integration engineer for systemic transport/unknown failures.
- Escalate to architect for emergency design-level changes.

## Done criteria
- Target transactions succeed.
- No new configuration validation errors.
- Change documentation complete.
