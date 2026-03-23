# Integration Support Runbook

## Purpose

This runbook provides operational guidance for supporting the Salesforce Case to ServiceNow Incident integration. It is intended for support analysts, administrators, and engineers responsible for monitoring, triage, and recovery.

## Support Objectives

- Detect failed or delayed integration transactions quickly.
- Restore business processing with minimal duplicate incident creation.
- Preserve auditability for retries, manual interventions, and configuration changes.
- Escalate security-sensitive issues through the correct channels.

## Monitoring Expectations

Support teams should monitor at least the following signals:

- failed outbound incident creation transactions,
- repeated retry exhaustion,
- missing ServiceNow incident identifiers on in-scope Cases,
- mismatched status values between Case and Incident,
- comment or attachment sync failures,
- and unusual spikes in routing or validation failures.

## Standard Triage Process

### 1. Confirm scope

- Identify the affected Salesforce Case.
- Determine whether a ServiceNow Incident was created.
- Confirm whether the issue affects one Case, one org, or multiple orgs.

### 2. Review integration logs

- Locate the integration transaction log entry.
- Record correlation identifiers, timestamps, retry counts, and last known error.
- Check whether the error occurred during validation, mapping, transport, or response handling.

### 3. Validate configuration

- Confirm the relevant org configuration is active.
- Confirm the correct routing rule and field mapping set are deployed.
- Check whether any feature toggle was recently changed.

### 4. Check secure connectivity

- Verify the Named Credential and External Credential are available and not expired.
- Confirm the integration principal still has required permissions.
- If authentication failures occur, engage the credential-owning team rather than bypassing security controls.

### 5. Decide recovery path

- Retry automatically if the failure type is transient and duplicate protection exists.
- Reprocess manually through approved admin tooling if safe.
- Escalate to engineering if the failure is caused by schema drift, code defects, or repeated mapping errors.

## Common Failure Modes

### Validation failure

**Symptoms:** missing required fields, unsupported request type, inactive routing configuration.

**Actions:**

- Correct the source Case data when appropriate.
- Confirm metadata completeness.
- Re-run the transaction only after data and configuration are valid.

### Authentication or endpoint failure

**Symptoms:** unauthorized response, endpoint unavailable, Named Credential errors.

**Actions:**

- Validate Named Credential and External Credential status.
- Confirm the ServiceNow endpoint is reachable through approved channels.
- Escalate to the credential or network owner if infrastructure is the root cause.

### Mapping or serialization failure

**Symptoms:** payload build exceptions, unsupported field transformations, response parsing errors.

**Actions:**

- Identify the affected field mapping or template.
- Check whether ServiceNow or Salesforce schema changed.
- Escalate to engineering for framework-level fixes if metadata correction alone is insufficient.

### Duplicate incident risk

**Symptoms:** timeout after submission, uncertain creation state, repeated retries.

**Actions:**

- Search logs and ServiceNow for an existing incident before retrying.
- Use correlation identifiers where available.
- Prefer idempotent reprocessing paths over manual recreation.

## Escalation Guidance

Escalate immediately when any of the following occurs:

- potential exposure of sensitive information,
- credential compromise or suspected misuse,
- repeated failures across multiple orgs,
- evidence of duplicate incident creation at scale,
- or unresolved integration outage beyond the agreed operational threshold.

## Change Management Expectations

- Treat routing and field-mapping metadata as controlled configuration.
- Log who changed configuration, when it changed, and why.
- Promote changes through normal environment management processes.
- Update this runbook and the field ownership matrix when new sync domains are introduced.
