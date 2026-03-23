public with sharing class SN_IncidentSyncQueueable implements Queueable, Database.AllowsCallouts {
    private final Id caseId;
    private final String requestTypeKey;
    private final String orgKey;
    private final String businessContext;

    public SN_IncidentSyncQueueable(Id caseId, String requestTypeKey, String orgKey, String businessContext) {
        this.caseId = caseId;
        this.requestTypeKey = requestTypeKey;
        this.orgKey = orgKey;
        this.businessContext = businessContext;
    }

    public void execute(QueueableContext context) {
        SN_IntegrationOrchestrator.RequestContext requestContext = new SN_IntegrationOrchestrator.RequestContext();
        requestContext.requestTypeKey = requestTypeKey;
        requestContext.orgKey = orgKey;
        requestContext.businessContext = businessContext;
        SN_IntegrationOrchestrator.orchestrate(caseId, requestContext);
    }
}
