# Reprocessing Runbook

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
