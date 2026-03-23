public with sharing class SN_FileSyncQueueable implements Queueable, Database.AllowsCallouts {
    private final Id caseId;
    private final Id contentVersionId;
    private final String incidentSysId;
    private final String orgKey;
    private final String requestTypeKey;

    public SN_FileSyncQueueable(Id caseId, Id contentVersionId, String incidentSysId, String orgKey, String requestTypeKey) {
        this.caseId = caseId;
        this.contentVersionId = contentVersionId;
        this.incidentSysId = incidentSysId;
        this.orgKey = orgKey;
        this.requestTypeKey = requestTypeKey;
    }

    public void execute(QueueableContext context) {
        SN_IncidentOrchestrationService.synchronizeFile(caseId, contentVersionId, incidentSysId, orgKey, requestTypeKey);
    }
}
