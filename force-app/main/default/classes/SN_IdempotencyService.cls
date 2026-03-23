public with sharing class SN_IdempotencyService {
    public class ReservationResult {
        public Id transactionId;
        public String idempotencyKey;
        public Boolean shouldProcess;
        public Boolean existingSuccess;
        public Boolean retryExecution;
        public String status;
        public String targetRecordId;
    }

    public static String buildKey(Id sourceRecordId, String operationName, String businessContext) {
        String raw = String.join(new List<String>{
            String.valueOf(sourceRecordId),
            String.isBlank(operationName) ? 'unknown' : operationName.trim().toLowerCase(),
            String.isBlank(businessContext) ? 'default' : businessContext.trim().toLowerCase()
        }, '|');
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(raw));
        return EncodingUtil.convertToHex(digest).substring(0, 100);
    }

    /** Finds an existing transaction for the supplied idempotency key, if one exists. */
    public static Id findExistingTransaction(String idempotencyKey) {
        Integration_Transaction__c transactionRecord = getByKey(idempotencyKey);
        return transactionRecord == null ? null : transactionRecord.Id;
    }

    /** Creates or reserves an idempotency key before asynchronous processing begins. */
    public static Id registerTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType) {
        return reserveTransaction(idempotencyKey, correlationId, orgCode, requestType, null, 'createIncident').transactionId;
    }

    public static ReservationResult reserveTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType, Id sourceRecordId) {
        return reserveTransaction(idempotencyKey, correlationId, orgCode, requestType, sourceRecordId, 'createIncident');
    }

    public static ReservationResult reserveTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType, Id sourceRecordId, String operationName) {
        if (String.isBlank(idempotencyKey)) {
            throw new IdempotencyException('Idempotency key is required.');
        }

        Integration_Transaction__c existing = getByKey(idempotencyKey);
        if (existing != null) {
            return hydrateExisting(existing, idempotencyKey);
        }

        try {
            Id transactionId = SN_TransactionLogService.startTransaction(
                correlationId,
                idempotencyKey,
                'Salesforce',
                String.isBlank(operationName) ? 'createIncident' : operationName,
                sourceRecordId,
                requestType,
                orgCode
            );
            ReservationResult created = new ReservationResult();
            created.transactionId = transactionId;
            created.idempotencyKey = idempotencyKey;
            created.shouldProcess = true;
            created.existingSuccess = false;
            created.retryExecution = false;
            created.status = 'Queued';
            return created;
        } catch (DmlException ex) {
            if (!ex.getMessage().contains('DUPLICATE_VALUE')) {
                throw ex;
            }
            Integration_Transaction__c duplicateRecord = getByKey(idempotencyKey);
            if (duplicateRecord == null) {
                throw ex;
            }
            return hydrateExisting(duplicateRecord, idempotencyKey);
        }
    }

    private static ReservationResult hydrateExisting(Integration_Transaction__c existing, String idempotencyKey) {
        ReservationResult result = new ReservationResult();
        result.transactionId = existing.Id;
        result.idempotencyKey = idempotencyKey;
        result.status = existing.Status__c;
        result.targetRecordId = existing.TargetRecordId__c;

        if (existing.Status__c == 'Succeeded') {
            result.shouldProcess = false;
            result.existingSuccess = true;
            result.retryExecution = false;
            return result;
        }

        if (existing.Status__c == 'Failed' || existing.Status__c == 'Abandoned') {
            Integer retryCount = existing.RetryCount__c == null ? 0 : Integer.valueOf(existing.RetryCount__c);
            update new Integration_Transaction__c(
                Id = existing.Id,
                Status__c = 'Retrying',
                RetryCount__c = retryCount + 1,
                StartedAt__c = System.now(),
                CompletedAt__c = null
            );
            result.shouldProcess = true;
            result.existingSuccess = false;
            result.retryExecution = true;
            result.status = 'Retrying';
            return result;
        }

        result.shouldProcess = false;
        result.existingSuccess = false;
        result.retryExecution = false;
        return result;
    }

    private static Integration_Transaction__c getByKey(String idempotencyKey) {
        if (String.isBlank(idempotencyKey)) {
            return null;
        }
        List<Integration_Transaction__c> records = [
            SELECT Id, IdempotencyKey__c, Status__c, RetryCount__c, TargetRecordId__c
            FROM Integration_Transaction__c
            WHERE IdempotencyKey__c = :idempotencyKey
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    public class IdempotencyException extends Exception {}
}
