public with sharing class SN_IncidentLinkService {
    public class LinkContext {
        public Id transactionId;
        public Id sourceRecordId;
        public String sourceObjectApiName;
        public String sourceRecordLabel;
        public String sourceRecordType;
        public String orgCode;
        public String businessUnit;
        public String serviceNowIncidentId;
        public String serviceNowIncidentNumber;
        public String linkStatus;
        public Datetime lastSyncAt;
    }

    public static void upsertLink(LinkContext context) {
        if (context == null || context.transactionId == null) {
            return;
        }

        List<ServiceNow_Incident_Link__c> existingLinks = [
            SELECT Id
            FROM ServiceNow_Incident_Link__c
            WHERE Integration_Transaction__c = :context.transactionId
            LIMIT 1
        ];

        ServiceNow_Incident_Link__c linkRecord = existingLinks.isEmpty()
            ? new ServiceNow_Incident_Link__c(Integration_Transaction__c = context.transactionId)
            : existingLinks[0];

        linkRecord.Salesforce_Record_Id__c = context.sourceRecordId == null ? null : String.valueOf(context.sourceRecordId);
        linkRecord.Source_Object_API_Name__c = context.sourceObjectApiName;
        linkRecord.Source_Record_Label__c = context.sourceRecordLabel;
        linkRecord.Source_Record_Type__c = context.sourceRecordType;
        linkRecord.Salesforce_Org_Code__c = context.orgCode;
        linkRecord.Business_Unit__c = context.businessUnit;
        linkRecord.ServiceNow_Incident_Id__c = context.serviceNowIncidentId;
        linkRecord.ServiceNow_Incident_Number__c = context.serviceNowIncidentNumber;
        linkRecord.Link_Status__c = String.isBlank(context.linkStatus) ? 'Active' : context.linkStatus;
        linkRecord.Last_Synchronized_At__c = context.lastSyncAt == null ? System.now() : context.lastSyncAt;

        upsert linkRecord;
    }

    public static LinkContext buildCaseIncidentContext(Id transactionId, Case caseRecord, String orgCode, String businessUnit,
        String serviceNowIncidentId, String serviceNowIncidentNumber, String linkStatus) {
        LinkContext context = new LinkContext();
        context.transactionId = transactionId;
        context.sourceRecordId = caseRecord == null ? null : caseRecord.Id;
        context.sourceObjectApiName = 'Case';
        context.sourceRecordLabel = caseRecord == null ? null : caseRecord.CaseNumber;
        context.sourceRecordType = caseRecord == null ? null : caseRecord.Type;
        context.orgCode = orgCode;
        context.businessUnit = businessUnit;
        context.serviceNowIncidentId = serviceNowIncidentId;
        context.serviceNowIncidentNumber = serviceNowIncidentNumber;
        context.linkStatus = linkStatus;
        context.lastSyncAt = System.now();
        return context;
    }
}
