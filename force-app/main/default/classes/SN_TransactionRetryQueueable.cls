public with sharing class SN_TransactionRetryQueueable implements Queueable, Database.AllowsCallouts {
    private final Id transactionId;

    /** Enqueues retry execution for a failed or retryable transaction. */
    public SN_TransactionRetryQueueable(Id transactionId) {
        this.transactionId = transactionId;
    }

    public void execute(QueueableContext context) {
    }
}
