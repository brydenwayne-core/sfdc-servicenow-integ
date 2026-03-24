# Process Flow: Replay and Reprocessing

## Purpose
Define controlled replay/reprocessing process for failed integration transactions.

## Eligibility Rules

1. Transaction must be in a terminal or retry-eligible state.
2. `Replay_Eligible__c` must be true.
3. Root cause should be corrected before replay.
4. In-flight or duplicate-prone transactions are excluded.

## Replay Flow

1. Operator reviews transaction, error history, and failure class.
2. Operator validates corrective action (metadata, credential, transient recovery).
3. Operator executes replay process (`SN_TransactionReplayService`).
4. Transaction proceeds through retry/in-progress terminal outcome.
5. Operator verifies ServiceNow link and transaction final status.

## Exception Paths

- Replay blocked by eligibility constraints.
- Replay fails with same class (root cause not resolved).
- Replay fails with new class (secondary issue revealed).

## Governance and Audit

- Replays must be attributable to operator and timestamp.
- High-volume replay events require incident review.
- Repeated replay patterns trigger metadata/process corrective action.

## Cross-links

- [Reprocessing Runbook](../runbooks/reprocessing-runbook.md)
- [Observability Architecture](../architecture/observability-architecture.md)
- [Failure Classification Flow](failure-classification-and-triage.md)
