# Integration Support Runbook

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

## Purpose

This runbook provides operational guidance for supporting the Salesforce Case to ServiceNow Incident integration. It is intended for support analysts, administrators, and engineers responsible for monitoring, triage, and recovery.

## What Support Analysts Should Look At First

When an incident is reported, review these items in order:

1. the affected Salesforce `Case`,
2. the related `Integration_Transaction__c` record,
3. the related `ServiceNow_Incident_Link__c` record,
4. the transaction's correlation ID, request type, org code, retry count, and safe summaries,
5. the org/request type/routing/mapping/toggle metadata that applies to that transaction.

If the failure appears credential-related or multi-org, escalate early instead of repeatedly retrying.

## Support Objectives

- Detect failed or delayed integration transactions quickly.
- Restore business processing with minimal duplicate incident creation.
- Preserve auditability for retries, manual interventions, and configuration changes.
- Escalate security-sensitive issues through the correct channels.

## Core Records and What They Mean

### `Integration_Transaction__c`

Primary support record for each integration attempt.

Key fields to review:

- `Status__c`
- `CorrelationId__c`
- `IdempotencyKey__c`
- `SourceRecordId__c`
- `RequestType__c`
- `SalesforceOrgCode__c`
- `RetryCount__c`
- `TargetRecordId__c`
- `ErrorCategory__c`
- `ErrorCode__c`
- `ErrorSummary__c`
- `Safe_Request_Summary__c`
- `Safe_Response_Summary__c`

### `ServiceNow_Incident_Link__c`

Used to confirm whether a Salesforce record has already been associated with a ServiceNow incident.

Key fields to review:

- ServiceNow incident ID and number,
- Salesforce org code,
- link status,
- source record label/type,
- last synchronized timestamp.

### Error objects

If present in the org, review `Integration_Error__c` and/or `SN_Integration_Error__c` for child error details captured for support triage.

## Transaction Status Reference

### `Queued`

The transaction was created and is waiting for processing.

Support action:

- verify async processing is running,
- verify the transaction does not remain stuck for an unusual duration.

### `In Progress`

The orchestration has started and is actively processing.

Support action:

- wait briefly if the record is recent,
- investigate if the record remains in this state beyond normal processing time.

### `Succeeded`

The transaction completed successfully.

Support action:

- confirm the target record id is populated,
- confirm the incident link exists and is accurate,
- no retry should be performed.

### `Retrying`

The transaction hit a retryable failure or is being reprocessed.

Support action:

- inspect the retry count,
- confirm the original failure is transient,
- avoid repeated manual retries without diagnosis.

### `Failed`

The transaction failed and is not currently in-flight.

Support action:

- determine the failure category,
- correct the underlying issue,
- reprocess only after the issue is understood.

### `Abandoned`

The transaction has been intentionally stopped or exceeded retry policy.

Support action:

- escalate to engineering or the owning admin,
- do not restart blindly.

## Common Failure Categories

### Configuration

Typical examples:

- missing or inactive `SN_Org_Config__mdt`,
- missing endpoint config,
- inactive request type,
- missing assignment target,
- missing routing default.

What support should do:

- validate metadata deployment state,
- compare working and failing org/request type combinations,
- engage the admin or release owner.

### Validation

Typical examples:

- required source data missing,
- unsupported request type,
- bad field mapping,
- ServiceNow rejects the payload with a 4xx response.

What support should do:

- identify the exact Case data or metadata gap,
- correct source data or configuration,
- retry after confirmation.

### Transport

Typical examples:

- timeout,
- 429 throttling,
- 5xx ServiceNow failure,
- callout/network issue.

What support should do:

- confirm whether the issue is transient,
- check whether duplicate creation is possible,
- use the idempotent retry path rather than creating a new transaction manually.

### Security

Typical examples:

- 401/403 response,
- expired credentials,
- Named Credential or External Credential problems.

What support should do:

- stop repeated retries,
- engage the credential-owning team,
- treat as a security-sensitive outage when appropriate.

### Unknown or unhandled

Typical examples:

- unexpected Apex exception,
- malformed downstream response,
- parsing issue.

What support should do:

- capture the correlation ID and error details,
- escalate to engineering with the exact transaction reference.

## Standard Triage Process

### 1. Confirm scope

- Identify the affected Salesforce Case.
- Determine whether a ServiceNow Incident was created.
- Confirm whether the issue affects one Case, one org, or multiple orgs.

### 2. Review integration logs

- Locate the integration transaction log entry.
- Record correlation identifiers, timestamps, retry counts, and last known error.
- Check whether the error occurred during validation, mapping, transport, routing, or response handling.

### 3. Check for duplicate risk before retrying

Before reprocessing:

- search `ServiceNow_Incident_Link__c`,
- search ServiceNow using the correlation ID or target incident details when available,
- confirm whether a timeout may have occurred after remote creation.

If duplicate risk cannot be ruled out, escalate instead of retrying immediately.

### 4. Validate configuration

- Confirm the relevant org configuration is active.
- Confirm the correct request type is active.
- Confirm the correct routing rule and field mapping set are deployed.
- Check whether any feature toggle was recently changed.

### 5. Check secure connectivity

- Verify the Named Credential and External Credential are available and not expired.
- Confirm the integration principal still has required permissions.
- If authentication failures occur, engage the credential-owning team rather than bypassing security controls.

### 6. Decide recovery path

- Retry automatically or through approved admin tooling if the failure type is transient and duplicate protection exists.
- Reprocess manually only after data/configuration issues are corrected.
- Escalate to engineering if the failure is caused by schema drift, code defects, malformed responses, or repeated mapping errors.

## Reprocessing Guidance

### Safe to consider reprocessing when

- the failure is clearly transient,
- idempotency is active,
- duplicate incident risk has been checked,
- data and configuration are now valid.

### Do not reprocess blindly when

- a ServiceNow incident may already exist,
- the error is authentication-related,
- the same transaction has already retried multiple times,
- the failure affects multiple orgs or all traffic.

### Recommended reprocessing approach

1. review the existing transaction,
2. fix configuration or source data if needed,
3. use the approved retry path tied to the existing transaction,
4. verify the final status and incident link after reprocessing.

## Monitoring Expectations

Support teams should monitor at least the following signals:

- failed outbound incident creation transactions,
- repeated retry exhaustion,
- missing ServiceNow incident identifiers on in-scope Cases,
- mismatched status values between Case and Incident,
- comment or attachment sync failures,
- unusual spikes in routing or validation failures,
- authentication failures across one or more orgs.

## Escalation Guidance

Escalate immediately when any of the following occurs:

- potential exposure of sensitive information,
- credential compromise or suspected misuse,
- repeated failures across multiple orgs,
- evidence of duplicate incident creation at scale,
- unresolved integration outage beyond the agreed operational threshold,
- malformed or inconsistent downstream responses that suggest contract drift.

## Change Management Expectations

- Treat routing and field-mapping metadata as controlled configuration.
- Log who changed configuration, when it changed, and why.
- Promote changes through normal environment management processes.
- Update the admin guide, this runbook, and the field ownership matrix when new sync domains are introduced.
