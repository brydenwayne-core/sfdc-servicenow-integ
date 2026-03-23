public with sharing class SN_TransactionLogService {
    public static Id startTransaction(String correlationId, String idempotencyKey, String sourceSystem, String operationName, Id sourceRecordId, String requestTypeKey, String orgCode, String businessUnit, String sourceObjectApiName, String sourceRecordLabel) {
        Integration_Transaction__c record = new Integration_Transaction__c(
            CorrelationId__c = correlationId,
            IdempotencyKey__c = idempotencyKey,
            SourceSystem__c = sourceSystem,
            Operation__c = operationName,
            SourceRecordId__c = sourceRecordId,
            RequestType__c = requestTypeKey,
            SalesforceOrgCode__c = orgCode,
            BusinessUnit__c = businessUnit,
            SourceObjectApiName__c = sourceObjectApiName,
            SourceRecordLabel__c = sourceRecordLabel,
            Status__c = 'Queued',
            Lifecycle_State__c = 'Queued',
            Support_Status__c = 'New',
            StartedAt__c = System.now(),
            RetryCount__c = 0,
            Replay_Eligible__c = true,
            ContainsSensitiveData__c = false
        );
        insert record;
        return record.Id;
    }
    public static void markInProgress(Id transactionId, String lifecycleState) { if (transactionId == null) return; update new Integration_Transaction__c(Id = transactionId, Status__c = 'In Progress', Lifecycle_State__c = String.isBlank(lifecycleState) ? 'In Progress' : lifecycleState, Support_Status__c = 'Monitoring'); }
    public static void markSuccess(Id transactionId, String targetRecordId, String safeResponseSummary) {
        if (transactionId == null) return;
        update new Integration_Transaction__c(Id = transactionId, Status__c = 'Succeeded', Lifecycle_State__c = 'Completed', Support_Status__c = 'Closed', TargetRecordId__c = targetRecordId, Safe_Response_Summary__c = safeResponseSummary, CompletedAt__c = System.now(), ErrorCategory__c = null, ErrorCode__c = null, ErrorSummary__c = null, Failure_Class__c = null, Next_Action__c = null);
    }
    public static void markFailure(Id transactionId, String errorCategory, String errorCode, String errorSummary, Boolean retryable, String safeContext) { markFailure(transactionId, errorCategory, null, errorCode, errorSummary, retryable, safeContext); }
    public static void markFailure(Id transactionId, String errorCategory, String failureClass, String errorCode, String errorSummary, Boolean retryable, String safeContext) {
        if (transactionId == null) return;
        Integration_Transaction__c current = [SELECT Id, Retry_History__c, RetryCount__c FROM Integration_Transaction__c WHERE Id = :transactionId LIMIT 1];
        String historyEntry = String.valueOf(System.now()) + '|' + (retryable == true ? 'RETRYABLE' : 'TERMINAL') + '|' + errorCode;
        String combinedHistory = String.isBlank(current.Retry_History__c) ? historyEntry : current.Retry_History__c + '\n' + historyEntry;
        update new Integration_Transaction__c(Id = transactionId, Status__c = retryable == true ? 'Retrying' : 'Failed', Lifecycle_State__c = retryable == true ? 'Awaiting Retry' : 'Failed', Support_Status__c = retryable == true ? 'Queued for Retry' : 'Action Required', ErrorCategory__c = errorCategory, Failure_Class__c = failureClass, ErrorCode__c = errorCode, ErrorSummary__c = errorSummary, Safe_Request_Summary__c = safeContext, Retry_History__c = combinedHistory, Last_Retry_At__c = retryable == true ? System.now() : null, Next_Action__c = retryable == true ? 'Review retry backlog and replay if still failing.' : 'Investigate configuration or data issue.', CompletedAt__c = retryable == true ? null : System.now(), Replay_Eligible__c = retryable == true || errorCategory != 'Security');
    }
}
