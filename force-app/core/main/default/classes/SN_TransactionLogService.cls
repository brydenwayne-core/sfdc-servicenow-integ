public with sharing class SN_TransactionLogService {
    /** Opens an observability transaction record using healthcare-safe metadata only. */
    public static Id startTransaction(String correlationId, String idempotencyKey, String sourceSystem, String operationName, Id sourceRecordId, String requestTypeKey, String orgCode, String businessUnit, String sourceObjectApiName, String sourceRecordLabel) {
        Integration_Transaction__c transactionRecord = new Integration_Transaction__c();
        transactionRecord.CorrelationId__c = correlationId;
        transactionRecord.IdempotencyKey__c = idempotencyKey;
        transactionRecord.SourceSystem__c = sourceSystem;
        transactionRecord.Operation__c = operationName;
        transactionRecord.SourceRecordId__c = sourceRecordId;
        transactionRecord.RequestType__c = requestTypeKey;
        transactionRecord.SalesforceOrgCode__c = orgCode;
        transactionRecord.BusinessUnit__c = businessUnit;
        transactionRecord.SourceObjectApiName__c = sourceObjectApiName;
        transactionRecord.SourceRecordLabel__c = sourceRecordLabel;
        transactionRecord.Status__c = 'Queued';
        transactionRecord.StartedAt__c = System.now();
        transactionRecord.RetryCount__c = 0;
        insert transactionRecord;
        return transactionRecord.Id;
    }

    /** Records a successful completion state for the transaction. */
    public static void markSuccess(Id transactionId, String targetRecordId, String safeResponseSummary) {
        if (transactionId == null) {
            return;
        }
        update new Integration_Transaction__c(
            Id = transactionId,
            Status__c = 'Succeeded',
            TargetRecordId__c = targetRecordId,
            Safe_Response_Summary__c = safeResponseSummary,
            CompletedAt__c = System.now(),
            ErrorCategory__c = null,
            ErrorCode__c = null,
            ErrorSummary__c = null
        );
    }

    /** Records a failure state and optional child error record for support triage. */
    public static void markFailure(Id transactionId, String errorCategory, String errorCode, String errorSummary, Boolean retryable, String safeContext) {
        if (transactionId == null) {
            return;
        }
        update new Integration_Transaction__c(
            Id = transactionId,
            Status__c = retryable == true ? 'Retrying' : 'Failed',
            ErrorCategory__c = errorCategory,
            ErrorCode__c = errorCode,
            ErrorSummary__c = errorSummary,
            Safe_Request_Summary__c = safeContext,
            CompletedAt__c = retryable == true ? null : System.now()
        );
    }
}
