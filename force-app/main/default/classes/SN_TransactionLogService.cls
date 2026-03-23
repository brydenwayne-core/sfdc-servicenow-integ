public with sharing class SN_TransactionLogService {
    /** Opens an observability transaction record using healthcare-safe metadata only. */
    public static Id startTransaction(String correlationId, String idempotencyKey, String sourceSystem, String operationName, Id sourceRecordId, String requestTypeKey, String orgCode) {
        return null;
    }

    /** Records a successful completion state for the transaction. */
    public static void markSuccess(Id transactionId, String targetRecordId, String safeResponseSummary) {
    }

    /** Records a failure state and optional child error record for support triage. */
    public static void markFailure(Id transactionId, String errorCategory, String errorCode, String errorSummary, Boolean retryable, String safeContext) {
    }
}
