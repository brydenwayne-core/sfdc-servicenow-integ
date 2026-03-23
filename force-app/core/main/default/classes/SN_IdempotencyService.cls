public with sharing class SN_IdempotencyService {
    public class ReservationResult {
        public Id transactionId; public String idempotencyKey; public Boolean shouldProcess; public Boolean existingSuccess; public Boolean retryExecution; public String status; public String targetRecordId;
    }
    public static String buildKey(Id sourceRecordId, String operationName, String businessContext) {
        String raw = String.join(new List<String>{ String.valueOf(sourceRecordId), normalize(operationName), normalize(businessContext) }, '|');
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(raw));
        return EncodingUtil.convertToHex(digest).substring(0, 100);
    }
    public static Id findExistingTransaction(String idempotencyKey) { Integration_Transaction__c t = getByKey(idempotencyKey, false); return t == null ? null : t.Id; }
    public static Id registerTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType) { return reserveTransaction(idempotencyKey, correlationId, orgCode, requestType, null, 'createIncident').transactionId; }
    public static ReservationResult reserveTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType, Id sourceRecordId) { return reserveTransaction(idempotencyKey, correlationId, orgCode, requestType, sourceRecordId, 'createIncident'); }
    public static ReservationResult reserveTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType, Id sourceRecordId, String operationName) {
        if (String.isBlank(idempotencyKey)) throw new IdempotencyException('Idempotency key is required.');
        Integration_Transaction__c existing = getByKey(idempotencyKey, true);
        if (existing != null) return hydrateExisting(existing, idempotencyKey);
        try {
            Id transactionId = SN_TransactionLogService.startTransaction(correlationId, idempotencyKey, 'Salesforce', String.isBlank(operationName) ? 'createIncident' : operationName, sourceRecordId, requestType, orgCode, null, null, null);
            ReservationResult created = new ReservationResult(); created.transactionId = transactionId; created.idempotencyKey = idempotencyKey; created.shouldProcess = true; created.existingSuccess = false; created.retryExecution = false; created.status = 'Queued'; return created;
        } catch (DmlException ex) {
            if (!ex.getMessage().contains('DUPLICATE_VALUE')) throw ex;
            Integration_Transaction__c duplicateRecord = getByKey(idempotencyKey, true);
            if (duplicateRecord == null) throw ex;
            return hydrateExisting(duplicateRecord, idempotencyKey);
        }
    }
    private static ReservationResult hydrateExisting(Integration_Transaction__c existing, String idempotencyKey) {
        ReservationResult result = new ReservationResult(); result.transactionId = existing.Id; result.idempotencyKey = idempotencyKey; result.status = existing.Status__c; result.targetRecordId = existing.TargetRecordId__c;
        if (existing.Status__c == 'Succeeded') { result.shouldProcess = false; result.existingSuccess = true; result.retryExecution = false; return result; }
        if (existing.Status__c == 'Failed' || existing.Status__c == 'Abandoned') {
            Integer retryCount = existing.RetryCount__c == null ? 0 : Integer.valueOf(existing.RetryCount__c);
            update new Integration_Transaction__c(Id = existing.Id, Status__c = 'Retrying', Lifecycle_State__c = 'Awaiting Retry', RetryCount__c = retryCount + 1, Last_Retry_At__c = System.now(), StartedAt__c = System.now(), CompletedAt__c = null);
            result.shouldProcess = true; result.existingSuccess = false; result.retryExecution = true; result.status = 'Retrying'; return result;
        }
        if (existing.Status__c == 'Queued' || existing.Status__c == 'In Progress' || existing.Status__c == 'Retrying') {
            result.shouldProcess = false; result.existingSuccess = false; result.retryExecution = false; throw new SN_ExceptionTaxonomy.IdempotencyConflictException('IDEMPOTENCY_LOCKED', 'A transaction is already active for key ' + idempotencyKey + '.');
        }
        result.shouldProcess = false; result.existingSuccess = false; result.retryExecution = false; return result;
    }
    private static Integration_Transaction__c getByKey(String idempotencyKey, Boolean forUpdate) {
        if (String.isBlank(idempotencyKey)) return null;
        String query = 'SELECT Id, IdempotencyKey__c, Status__c, RetryCount__c, TargetRecordId__c FROM Integration_Transaction__c WHERE IdempotencyKey__c = :idempotencyKey LIMIT 1';
        if (forUpdate) query += ' FOR UPDATE';
        List<Integration_Transaction__c> records = Database.query(query);
        return records.isEmpty() ? null : records[0];
    }
    private static String normalize(String value) { return String.isBlank(value) ? 'default' : value.trim().toLowerCase().replaceAll('\\s+', ' '); }
    public class IdempotencyException extends Exception {}
}
