# Reprocessing Runbook

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
Use controlled replay only for transactions marked `Replay_Eligible__c = true` and currently in `Failed`, `Retrying`, or `Abandoned` state.

## Process
1. Review `ErrorCategory__c`, `Failure_Class__c`, and `Retry_History__c`.
2. Correct the upstream configuration or transient transport condition.
3. Call `SN_TransactionReplayService.replay(transactionId)`.
4. Confirm the transaction moves through `Retrying` / `In Progress` and ends in `Succeeded` or a newly classified failure.

## Constraints
- Replay does not bypass idempotency protections.
- Active in-flight transactions should not be replayed.
- Security failures should be reviewed before replay because eligibility may be removed.
