public with sharing class SN_ConfigValidationService {
    public class ValidationMessage {
        @AuraEnabled public String severity;
        @AuraEnabled public String code;
        @AuraEnabled public String area;
        @AuraEnabled public String orgKey;
        @AuraEnabled public String requestTypeKey;
        @AuraEnabled public String detail;
    }
    public class ValidationReport {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public List<ValidationMessage> messages = new List<ValidationMessage>();
        public void add(String severity, String code, String area, String orgKey, String requestTypeKey, String detail){ ValidationMessage m=new ValidationMessage(); m.severity=severity; m.code=code; m.area=area; m.orgKey=orgKey; m.requestTypeKey=requestTypeKey; m.detail=detail; messages.add(m); if(severity=='ERROR') isValid=false; }
        public String toAdminSummary(){ List<String> lines=new List<String>(); for(ValidationMessage m:messages) lines.add(m.severity + ' [' + m.code + '] ' + m.detail); return String.join(lines, '\n'); }
    }
    public static ValidationReport validateAll(){
        ValidationReport report = new ValidationReport(); report.isValid = true;
        List<SN_Org_Config__mdt> orgs = SN_ConfigService.getOrgConfigRecords();
        List<SN_Request_Type__mdt> requestTypes = SN_ConfigService.getRequestTypeRecords();
        List<SN_Routing_Rule__mdt> routes = SN_ConfigService.getRoutingRuleRecords();
        List<SN_Assignment_Target__mdt> targets = SN_ConfigService.getAssignmentTargetRecords();
        List<SN_Incident_Template__mdt> templates = SN_ConfigService.getIncidentTemplateRecords();
        List<SN_Endpoint_Config__mdt> endpoints = SN_ConfigService.getEndpointConfigRecords();
        Map<String,SN_Assignment_Target__mdt> targetsByKey=new Map<String,SN_Assignment_Target__mdt>(); for(SN_Assignment_Target__mdt t:targets) if(t.Is_Active__c==true) targetsByKey.put((String.isBlank(t.Org_Key__c)?'__GLOBAL__':t.Org_Key__c)+'|'+t.Assignment_Target_Key__c,t);
        Set<String> templateKeys=new Set<String>(); for(SN_Incident_Template__mdt t:templates) if(t.Is_Active__c==true) templateKeys.add((String.isBlank(t.Org_Key__c)?'__GLOBAL__':t.Org_Key__c)+'|'+t.Incident_Template_Key__c);
        Set<String> endpointKeys=new Set<String>(); for(SN_Endpoint_Config__mdt e:endpoints) if(e.Is_Active__c==true) endpointKeys.add(e.Endpoint_Config_Key__c);
        Set<String> orgKeys=new Set<String>();
        for(SN_Org_Config__mdt orgCfg:orgs){ if(orgCfg.Is_Active__c!=true) continue; orgKeys.add(orgCfg.Org_Key__c); if(String.isBlank(orgCfg.Default_Request_Type__c)) report.add('ERROR','ORG_DEFAULT_REQUEST_TYPE_MISSING','Org Config',orgCfg.Org_Key__c,null,'Active org config is missing a default request type.'); if(String.isBlank(orgCfg.Endpoint_Config_Key__c) || !endpointKeys.contains(orgCfg.Endpoint_Config_Key__c)) report.add('ERROR','ORG_ENDPOINT_INVALID','Org Config',orgCfg.Org_Key__c,null,'Org config references a missing or inactive endpoint config.'); }
        if(orgKeys.isEmpty()) report.add('ERROR','ORG_CONFIG_MISSING','Org Config',null,null,'No active org configurations were found.');
        Map<String, Integer> fieldConflicts = new Map<String, Integer>();
        for (SN_Field_Mapping__mdt mapping : SN_FieldMappingService.getRecords()) {
            if (mapping.Is_Active__c != true) continue;
            String key = (String.isBlank(mapping.Org_Key__c)?'__GLOBAL__':mapping.Org_Key__c) + '|' + mapping.Request_Type_Key__c + '|' + mapping.Target_Field_API__c;
            fieldConflicts.put(key, (fieldConflicts.containsKey(key)?fieldConflicts.get(key):0) + 1);
        }
        for (String key : fieldConflicts.keySet()) if (fieldConflicts.get(key) > 1) report.add('ERROR','FIELD_MAPPING_CONFLICT','Field Mapping', key.split('\|')[0], key.split('\|')[1], 'Multiple active field mappings target the same field: ' + key.split('\|')[2] + '.');
        for(SN_Request_Type__mdt requestType:requestTypes){ if(requestType.Is_Active__c!=true) continue; String orgScope=String.isBlank(requestType.Org_Key__c)?'__GLOBAL__':requestType.Org_Key__c; if(!String.isBlank(requestType.Org_Key__c) && !orgKeys.contains(requestType.Org_Key__c)) report.add('ERROR','REQUEST_TYPE_ORG_MISSING','Request Type',requestType.Org_Key__c,requestType.Request_Type_Key__c,'Request type references an org without active org config.'); String templateKey = orgScope + '|' + requestType.Incident_Template_Key__c; String globalTemplateKey='__GLOBAL__|' + requestType.Incident_Template_Key__c; if(String.isBlank(requestType.Incident_Template_Key__c) || (!templateKeys.contains(templateKey) && !templateKeys.contains(globalTemplateKey))) report.add('ERROR','INCIDENT_TEMPLATE_MISSING','Request Type',requestType.Org_Key__c,requestType.Request_Type_Key__c,'Request type is missing an active incident template.'); if(!SN_FeatureToggleService.isEnabled('CASE_TO_INCIDENT_SYNC', requestType.Org_Key__c, requestType.Request_Type_Key__c)) report.add('WARN','FEATURE_DISABLED','Feature Toggle',requestType.Org_Key__c,requestType.Request_Type_Key__c,'Primary case-to-incident sync toggle is disabled for this request type.'); }
        for(SN_Routing_Rule__mdt route:routes){ if(route.Is_Active__c!=true) continue; String orgScope=String.isBlank(route.Org_Key__c)?'__GLOBAL__':route.Org_Key__c; if(String.isBlank(route.Assignment_Target_Key__c) || (!targetsByKey.containsKey(orgScope+'|'+route.Assignment_Target_Key__c) && !targetsByKey.containsKey('__GLOBAL__|'+route.Assignment_Target_Key__c))) report.add('ERROR','ROUTING_TARGET_INVALID','Routing',route.Org_Key__c,route.Request_Type_Key__c,'Routing rule references an invalid assignment target.'); }
        return report;
    }
}
