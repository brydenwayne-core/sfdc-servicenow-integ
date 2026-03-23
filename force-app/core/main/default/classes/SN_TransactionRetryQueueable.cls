public with sharing class SN_TransactionRetryQueueable implements Queueable, Database.AllowsCallouts {
    private final Id transactionId;

    public SN_TransactionRetryQueueable(Id transactionId) {
        this.transactionId = transactionId;
    }

    public void execute(QueueableContext context) {
        SN_IncidentOrchestrationService.retryTransaction(transactionId);
    }
}
