# Feature Toggle Runbook

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
