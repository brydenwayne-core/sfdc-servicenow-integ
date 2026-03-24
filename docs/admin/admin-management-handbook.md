# Salesforce-ServiceNow Integration Admin Management Handbook

## Purpose
Provide a complete administration playbook for Salesforce admins and ISS support managers to own this integration package safely.

## Audience
- Salesforce Administrators
- ISS Support Managers
- Release Managers

## Scope
- Configuration setup and onboarding
- Custom Metadata lifecycle management
- Feature toggle operations
- Named Credential setup and validation
- Routing administration
- Field mapping updates
- Request type activation/deactivation
- Monitoring and control-plane usage
- Safe change management

---

## 1) Configuration setup (Day 0 + Day 1)

### 1.1 Prerequisites
- Package metadata deployed (`force-app/core`, `force-app/config`, and `force-app/admin`).
- Integration permissions assigned (`SN_Integration_Admin`, `SN_Integration_Support`, `SN_Integration_Operator`).
- Named Credential + External Credential in place.
- ServiceNow assignment IDs, required payload fields, and endpoint details confirmed.

### 1.2 Core metadata dependency chain
1. `SN_Endpoint_Config__mdt`
2. `SN_Org_Config__mdt`
3. `SN_Incident_Template__mdt`
4. `SN_Request_Type__mdt`
5. `SN_Assignment_Target__mdt`
6. `SN_Routing_Rule__mdt`
7. `SN_Field_Mapping__mdt`
8. `SN_Feature_Toggle__mdt`

**Rule:** Activate top-to-bottom to avoid partial configuration states.

### 1.3 Required admin tabs for operations
- `Integration_Transaction__c`
- `Integration_Error__c`
- `SN_Integration_Run__c`
- `SN_Integration_Error__c`
- `ServiceNow_Incident_Link__c`

Use the packaged admin app (`ServiceNow_Integration_Admin`) for support workflows.

---

## 2) Custom Metadata maintenance model

Every metadata change should maintain both **business fields** and **governance fields**.

### 2.1 Governance fields to maintain on each CMT record
- `Is_Active__c`
- `Lifecycle_Status__c` (`Draft`, `Active`, `Deprecated`, `Retired`)
- `Effective_Start_Date__c`
- `Effective_End_Date__c`
- `Admin_Notes__c` / `Comments__c` / `Notes__c`
- `Documentation_URL__c`

### 2.2 Minimum quality checks before deploy
- No orphan references (org/request type/routing/target/template/endpoint).
- No duplicate active field mappings for the same target field and scope.
- Exactly one effective default route per active request type.
- Feature dependencies satisfied (`Depends_On_Feature__c`).
- Effective dates do not overlap for equivalent keys.

### 2.3 Validation routine
Run configuration validation prior to release and after production deploy:
- Execute `SN_ConfigValidationService.validateAll()`.
- Treat all `ERROR` messages as release blockers.
- Resolve `WARN` messages or record explicit risk acceptance.

---

## 3) Feature toggle operations

`SN_Feature_Toggle__mdt` supports global, org-specific, and request-type-specific behavior.

### 3.1 Resolution order and behavior
- Scope precedence: `org + requestType` → `org + global requestType` → global org scopes.
- Toggle must be enabled (`Is_Enabled__c = true`) to be active.
- Kill switch behavior: `<FEATURE_KEY>_KILL_SWITCH` with `Is_Kill_Switch__c = true` and enabled state overrides normal enablement.
- Dependency behavior: `Depends_On_Feature__c` must also resolve enabled.

### 3.2 Standard rollout pattern
1. Create toggle in `Draft` with notes and owner.
2. Enable in lower environment by org scope.
3. Validate transaction outcomes and error trend.
4. Promote to production for pilot org(s).
5. Expand rollout group in phases.
6. Keep a tested kill switch record available for rapid rollback.

### 3.3 Emergency rollback
- Enable the relevant kill switch.
- Confirm new transactions stop using target behavior.
- Preserve historical records; do not delete toggles during incidents.

---

## 4) Named Credential and endpoint administration

### 4.1 Configuration assets
- External Credential: `ServiceNow_External_Credential`
- Named Credential: `ServiceNow_Named_Credential`
- Endpoint metadata: `SN_Endpoint_Config__mdt.Named_Credential__c`, `Base_Path__c`, `Timeout_Ms__c`

### 4.2 Required checks
- Named Credential name exactly matches endpoint metadata reference.
- Integration principal authentication is valid (not expired/revoked).
- Base path and timeout align with ServiceNow API profile.
- Endpoint metadata is active before org config goes active.

### 4.3 Failure signals indicating credential/endpoint issues
- Error codes: `MISSING_ENDPOINT_CONFIG`, `AUTH_FAILURE`, `CALLOUT_TIMEOUT`, `CALLOUT_EXCEPTION`.
- Transaction error categories: `Configuration`, `Security`, or `Transport`.

---

## 5) Routing administration

Routing is controlled by `SN_Routing_Rule__mdt` + `SN_Assignment_Target__mdt`.

### 5.1 Rule design standard
- Maintain one safe default rule (`Is_Default__c=true`) per active request type.
- Use low numeric priority for specific rules; reserve higher values for defaults.
- Keep match criteria deterministic; avoid overlapping rules that can both match.
- Keep `Match_Criteria__c` JSON simple and testable.

### 5.2 `Match_Criteria__c` JSON pattern
```json
{
  "when": {
    "priority": ["High", "Critical"],
    "origin": "Phone"
  },
  "then": {
    "assignmentTargetKey": "US_Tier2_Group",
    "incidentTemplateKey": "__REQUEST_TYPE_DEFAULT__",
    "syncComments": true,
    "syncFiles": false
  }
}
```

### 5.3 Post-change verification
- Submit representative test cases for each routing branch.
- Confirm `matchedRuleDeveloperName`, fallback usage, and assignment target output.
- Ensure there are no routing conflicts (`RoutingException` scenarios).

---

## 6) Field mapping update operations

`SN_Field_Mapping__mdt` defines outbound payload construction.

### 6.1 Supported transform strategies
- `Direct`
- `Static Value`
- `Uppercase`
- `Lowercase`
- `Trim`
- `Org Key`
- `Request Type Key`

### 6.2 Mapping change checklist
1. Confirm target ServiceNow field API name.
2. Confirm source path (`Case.<Field>` or related data path).
3. Set non-conflicting `Sequence__c`.
4. Keep one active mapping per scope/requestType/target field.
5. Deploy and test with real-case representative data.
6. Verify safe request/response summaries in logs.

### 6.3 Anti-patterns
- Multiple active mappings targeting same field in same scope.
- Encoding routing decisions in mappings.
- Deploying inactive dependencies (request type/template/routing) with active mappings.

---

## 7) Request type activation and lifecycle

`SN_Request_Type__mdt` controls which workflows are available.

### 7.1 Activation prerequisites
- Active org config exists.
- Referenced incident template exists and is active.
- Routing key has valid active route(s).
- Field mappings exist for required ServiceNow payload fields.
- Primary feature toggle for sync (`CASE_TO_INCIDENT_SYNC`) is enabled where required.

### 7.2 Activation sequence
1. Create request type in `Draft`.
2. Deploy dependencies (template, mappings, routing, assignment target).
3. Enable in sandbox and execute test transaction set.
4. Promote and activate in production with controlled rollout.

### 7.3 Deactivation sequence
1. Stop intake for request type (business comms + UI/process controls).
2. Disable toggle(s) if needed.
3. Mark request type inactive and `Deprecated`/`Retired`.
4. Leave history intact for audits; do not hard-delete CMT history.

---

## 8) Monitoring and operational usage

### 8.1 Transaction status model
`Queued` → `In Progress` → `Succeeded` or (`Retrying` / `Failed` / `Abandoned`)

### 8.2 First-response monitoring fields
From `Integration_Transaction__c`:
- `Status__c`, `Support_Status__c`, `Lifecycle_State__c`
- `ErrorCategory__c`, `Failure_Class__c`, `ErrorCode__c`, `ErrorSummary__c`
- `RetryCount__c`, `Replay_Eligible__c`, `Last_Retry_At__c`, `Next_Action__c`
- `CorrelationId__c`, `IdempotencyKey__c`, `RequestType__c`, `SalesforceOrgCode__c`

### 8.3 Daily admin health checks
- Review failed transactions by org and request type.
- Confirm retry backlog is within SLA.
- Review configuration or security-related failures first.
- Sample-check success records for incident-link integrity.
- Track high-frequency error codes for proactive remediation.

---

## 9) Safe change management practices

### 9.1 Change classes
- **Standard:** low-risk metadata text/tuning updates.
- **Normal:** request type/routing/mapping/toggle behavior changes.
- **Emergency:** kill switch activation, auth outage response, replay suppression.

### 9.2 Pre-production gate checklist
- Peer review complete.
- Validation report clean (no `ERROR`).
- Regression test cases executed for changed org/request type pairs.
- Rollback plan documented (toggle rollback and metadata rollback).
- ISS and ServiceNow stakeholders notified.

### 9.3 Production deployment protocol
1. Deploy metadata package.
2. Validate endpoint and feature toggle state.
3. Submit a controlled smoke transaction.
4. Confirm `Succeeded` and link creation.
5. Monitor 30–60 minutes for drift/failure spikes.

### 9.4 Recovery guardrails
- Never bulk replay failed records until root cause is known.
- For timeout-like errors, check duplicate risk before replay.
- For `Security` failures, stop retries and escalate to credential owners.
- Preserve audit trail in `Admin_Notes__c` and change records.

---

## 10) RACI snapshot for admin ownership

| Activity | Salesforce Admin | ISS Support Manager | Integration Engineer | Architect/Application Owner |
| --- | --- | --- | --- | --- |
| Metadata maintenance | **R/A** | C | C | I |
| Feature rollout/kill switch | **R** | **A** | C | I |
| Named Credential upkeep | **R** | C | C | A |
| Incident triage workflow | C | **R/A** | R | I |
| Replay decisions for high-risk failures | C | **A** | **R** | C |
| Design-level routing/model changes | C | I | R | **A** |

R = Responsible, A = Accountable, C = Consulted, I = Informed.
