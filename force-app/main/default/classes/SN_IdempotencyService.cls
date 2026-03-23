public with sharing class SN_IdempotencyService {
    /** Finds an existing transaction for the supplied idempotency key, if one exists. */
    public static Id findExistingTransaction(String idempotencyKey) {
        return null;
    }

    /** Creates or reserves an idempotency key before asynchronous processing begins. */
    public static Id registerTransaction(String idempotencyKey, String correlationId, String orgCode, String requestType) {
        return null;
    }
}
