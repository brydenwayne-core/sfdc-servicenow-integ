public with sharing class SN_CaseIntakeSupport {
    public class RequestTypeDescriptor {
        @AuraEnabled public String requestTypeKey;
        @AuraEnabled public String label;
        @AuraEnabled public String orgKey;
        @AuraEnabled public String operationMode;
        @AuraEnabled public String routingKey;
        @AuraEnabled public String incidentTemplateKey;
        @AuraEnabled public String supportedSourceObject;
        @AuraEnabled public Boolean isActive;
    }

    @AuraEnabled(cacheable=true)
    public static List<RequestTypeDescriptor> getCaseIntakeRequestTypes(String orgKey) {
        String effectiveOrgKey = String.isBlank(orgKey) ? 'DEFAULT' : orgKey;
        List<RequestTypeDescriptor> descriptors = new List<RequestTypeDescriptor>();
        for (SN_Request_Type__mdt record : [
            SELECT DeveloperName, MasterLabel, Org_Key__c, Request_Type_Key__c, Source_Object__c,
                Operation_Mode__c, Routing_Key__c, Incident_Template_Key__c, Is_Active__c
            FROM SN_Request_Type__mdt
            WHERE Is_Active__c = true
            ORDER BY MasterLabel ASC
        ]) {
            if (!(record.Org_Key__c == effectiveOrgKey || String.isBlank(record.Org_Key__c))) {
                continue;
            }
            if (record.Source_Object__c != 'Case') {
                continue;
            }
            descriptors.add(toDescriptor(record));
        }
        return descriptors;
    }

    public static RequestTypeDescriptor describeRequestType(String orgKey, String requestTypeKey) {
        if (String.isBlank(requestTypeKey)) {
            SN_ConfigService.OrgConfig orgConfig = SN_ConfigService.getOrgConfigWrapper(orgKey);
            requestTypeKey = orgConfig == null ? null : orgConfig.defaultRequestTypeKey;
        }
        if (String.isBlank(requestTypeKey)) {
            return null;
        }
        SN_ConfigService.RequestTypeConfig config = SN_ConfigService.getRequestTypeConfigWrapper(orgKey, requestTypeKey);
        if (config == null || config.sourceObject != 'Case') {
            return null;
        }
        RequestTypeDescriptor descriptor = new RequestTypeDescriptor();
        descriptor.requestTypeKey = config.requestTypeKey;
        descriptor.label = config.developerName;
        descriptor.orgKey = config.orgKey;
        descriptor.operationMode = config.operationMode;
        descriptor.routingKey = config.routingKey;
        descriptor.incidentTemplateKey = config.incidentTemplateKey;
        descriptor.supportedSourceObject = config.sourceObject;
        descriptor.isActive = config.isActive;
        return descriptor;
    }

    private static RequestTypeDescriptor toDescriptor(SN_Request_Type__mdt record) {
        RequestTypeDescriptor descriptor = new RequestTypeDescriptor();
        descriptor.requestTypeKey = record.Request_Type_Key__c;
        descriptor.label = record.MasterLabel;
        descriptor.orgKey = record.Org_Key__c;
        descriptor.operationMode = record.Operation_Mode__c;
        descriptor.routingKey = record.Routing_Key__c;
        descriptor.incidentTemplateKey = record.Incident_Template_Key__c;
        descriptor.supportedSourceObject = record.Source_Object__c;
        descriptor.isActive = record.Is_Active__c;
        return descriptor;
    }
}
