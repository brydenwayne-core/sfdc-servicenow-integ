public with sharing class SN_IncidentSyncQueueable implements Queueable, Database.AllowsCallouts {
    private final Id transactionId;

    /** Enqueues asynchronous ServiceNow incident processing for a previously-logged transaction. */
    public SN_IncidentSyncQueueable(Id transactionId) {
        this.transactionId = transactionId;
    }

    public void execute(QueueableContext context) {
    }
}
