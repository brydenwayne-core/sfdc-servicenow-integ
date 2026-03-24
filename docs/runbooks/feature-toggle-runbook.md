# Feature Toggle Runbook

## Purpose
Provide operational response procedures for day-to-day support and incidents.

## Audience
Support analysts, integration operators, on-call engineers

## Scope
Operational execution steps, escalation points, and recovery controls.

## Related Documents
- [Documentation Taxonomy Standard](../architecture/documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

## Operating model
- Use a **global feature toggle** to define the package default for a capability.
- Add **org-scoped overrides** when rollout must differ by tenant or business unit.
- Add **request-type-scoped overrides** when a capability is only safe for a subset of intake patterns.
- Use a `*_KILL_SWITCH` toggle with `Is_Kill_Switch__c = true` for emergency shutdown. Kill switches override normal enablement.
- Use `Depends_On_Feature__c` when one feature must not activate unless a prerequisite control is already enabled.

## Rollout pattern
1. Enable the global toggle in lower environments only.
2. Enable org-specific entries for pilot orgs.
3. Add request-type-specific records for phased release cohorts.
4. Keep a kill-switch record deployed but disabled so support can activate it quickly during an incident.

## Incident response
- If ServiceNow behavior becomes unsafe, enable the matching kill switch record immediately.
- Validate the current config using `SN_ConfigValidationService.validateAll()` before re-enabling the feature.
- Review `Integration_Transaction__c` records filtered by `SalesforceOrgCode__c`, `RequestType__c`, and `Failure_Class__c` to confirm stabilization.
