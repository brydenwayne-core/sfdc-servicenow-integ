@IsTest
public with sharing class TestDataFactory {
    public class MetadataBundle {
        public List<SN_Org_Config__mdt> orgConfigs = new List<SN_Org_Config__mdt>();
        public List<SN_Request_Type__mdt> requestTypes = new List<SN_Request_Type__mdt>();
        public List<SN_Routing_Rule__mdt> routingRules = new List<SN_Routing_Rule__mdt>();
        public List<SN_Assignment_Target__mdt> assignmentTargets = new List<SN_Assignment_Target__mdt>();
        public List<SN_Field_Mapping__mdt> fieldMappings = new List<SN_Field_Mapping__mdt>();
        public List<SN_Feature_Toggle__mdt> featureToggles = new List<SN_Feature_Toggle__mdt>();
        public List<SN_Endpoint_Config__mdt> endpointConfigs = new List<SN_Endpoint_Config__mdt>();
        public List<SN_Incident_Template__mdt> incidentTemplates = new List<SN_Incident_Template__mdt>();
    }

    public static Account createAccount(Boolean doInsert) {
        Account accountRecord = new Account(Name = 'Test Hospital ' + uniqueSuffix());
        if (doInsert) {
            insert accountRecord;
        }
        return accountRecord;
    }

    public static Contact createContact(Id accountId, Boolean doInsert) {
        Contact contactRecord = new Contact(
            FirstName = 'Test',
            LastName = 'Contact ' + uniqueSuffix(),
            AccountId = accountId,
            Email = 'contact+' + uniqueSuffix() + '@example.test'
        );
        if (doInsert) {
            insert contactRecord;
        }
        return contactRecord;
    }

    public static ServiceNow_Incident_Link__c createIncidentLink(Id transactionId, Id caseId, String orgKey, String status, Boolean doInsert) {
        ServiceNow_Incident_Link__c record = new ServiceNow_Incident_Link__c(
            Integration_Transaction__c = transactionId,
            Salesforce_Record_Id__c = caseId == null ? null : String.valueOf(caseId),
            Source_Object_API_Name__c = 'Case',
            Source_Record_Label__c = 'CASE-' + uniqueSuffix(),
            Source_Record_Type__c = 'Support',
            Salesforce_Org_Code__c = orgKey,
            Business_Unit__c = orgKey + ' Business',
            ServiceNow_Incident_Id__c = 'sys_' + uniqueSuffix(),
            ServiceNow_Incident_Number__c = 'INC' + uniqueDigits(7),
            Link_Status__c = String.isBlank(status) ? 'Active' : status,
            Last_Synchronized_At__c = System.now()
        );
        if (doInsert) {
            insert record;
        }
        return record;
    }

    public static MetadataBundle createBaselineMetadata() {
        MetadataBundle bundle = new MetadataBundle();
        bundle.orgConfigs.add(orgConfig('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'SNOW_US_PROD', true, 'Healthcare East'));
        bundle.orgConfigs.add(orgConfig('ORG_A', 'REQUEST_X', 'SNOW_US_PROD', true, 'Org A Business'));
        bundle.orgConfigs.add(orgConfig('ORG_B', 'REQUEST_Y', 'SNOW_EMEA_PROD', true, 'Org B Business'));
        bundle.orgConfigs.add(orgConfig('ORG_DISABLED', 'REQUEST_DISABLED', 'SNOW_US_PROD', false, 'Disabled Org'));

        bundle.requestTypes.add(requestType('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'TEMPLATE_STANDARD', 'CASE_ROUTING', true));
        bundle.requestTypes.add(requestType('ORG_A', 'REQUEST_X', 'TEMPLATE_A', 'ROUTING_A', true));
        bundle.requestTypes.add(requestType('ORG_B', 'REQUEST_Y', 'TEMPLATE_B', 'ROUTING_B', true));
        bundle.requestTypes.add(requestType(null, 'REQUEST_SHARED', 'TEMPLATE_SHARED', 'ROUTING_SHARED', true));

        bundle.assignmentTargets.add(assignmentTarget('US_HEALTHCARE_PROD', 'US_TIER2', 'Group', 'group-us-tier2', true));
        bundle.assignmentTargets.add(assignmentTarget('US_HEALTHCARE_PROD', 'US_DEFAULT', 'Queue', 'queue-us-default', true));
        bundle.assignmentTargets.add(assignmentTarget('ORG_A', 'ORG_A_TARGET', 'Group', 'group-org-a', true));
        bundle.assignmentTargets.add(assignmentTarget('ORG_B', 'ORG_B_TARGET', 'Group', 'group-org-b', true));
        bundle.assignmentTargets.add(assignmentTarget('ORG_B', 'ORG_B_FALLBACK', 'Queue', 'queue-org-b-fallback', true));
        bundle.assignmentTargets.add(assignmentTarget(null, 'GLOBAL_TARGET', 'Queue', 'queue-global', true));

        bundle.routingRules.add(routingRule('US_HIGH_PRIORITY', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'US_TIER2', 10, false,
            '{"when":{"priority":"high","origin":["phone","web"]},"then":{"incidentTemplateKey":"TEMPLATE_HIGH","syncComments":true,"syncFiles":true}}', true));
        bundle.routingRules.add(routingRule('US_DEFAULT', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'US_DEFAULT', 90, true,
            '{"then":{"incidentTemplateKey":"__REQUEST_TYPE_DEFAULT__","syncComments":false,"syncFiles":false}}', true));
        bundle.routingRules.add(routingRule('ORG_A_REQUEST_X', 'ORG_A', 'REQUEST_X', 'ORG_A_TARGET', 5, false,
            '{"when":{"priority":"high"},"then":{"priorityBehavior":"P1_OVERRIDE","syncComments":true}}', true));
        bundle.routingRules.add(routingRule('ORG_B_DEFAULT', 'ORG_B', 'REQUEST_Y', 'ORG_B_FALLBACK', 99, true,
            '{"then":{"incidentTemplateKey":"__REQUEST_TYPE_DEFAULT__","stopDownstreamProcessing":true}}', true));
        bundle.routingRules.add(routingRule('GLOBAL_SHARED', null, 'REQUEST_SHARED', 'GLOBAL_TARGET', 100, true,
            '{"then":{"incidentTemplateKey":"TEMPLATE_SHARED"}}', true));

        bundle.fieldMappings.add(fieldMapping('GLOBAL_CATEGORY', null, 'INCIDENT_STANDARD', null, 'category', 'Static Value', 'general', 1, true));
        bundle.fieldMappings.add(fieldMapping('US_SHORT_DESCRIPTION', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'Case.Subject', 'short_description', 'Trim', null, 2, true));
        bundle.fieldMappings.add(fieldMapping('US_DESCRIPTION', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'Case.Description', 'description', 'Direct', null, 3, true));
        bundle.fieldMappings.add(fieldMapping('US_PRIORITY', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'Case.Priority', 'priority', 'Lowercase', null, 4, true));
        bundle.fieldMappings.add(fieldMapping('ORG_A_SHORT_DESCRIPTION', 'ORG_A', 'REQUEST_X', 'Case.Subject', 'short_description', 'Uppercase', null, 1, true));
        bundle.fieldMappings.add(fieldMapping('ORG_B_SHORT_DESCRIPTION', 'ORG_B', 'REQUEST_Y', 'Case.Subject', 'short_description', 'Lowercase', null, 1, true));
        bundle.fieldMappings.add(fieldMapping('ORG_B_REQUEST_TYPE', 'ORG_B', 'REQUEST_Y', null, 'u_request_type', 'Request Type Key', null, 2, true));
        bundle.fieldMappings.add(fieldMapping('GLOBAL_SHARED_DESCRIPTION', null, 'REQUEST_SHARED', 'Case.Description', 'description', 'Trim', null, 1, true));

        bundle.incidentTemplates.add(incidentTemplate('US_HEALTHCARE_PROD', 'TEMPLATE_STANDARD', 'inquiry', 'general', '2', '2', true));
        bundle.incidentTemplates.add(incidentTemplate('ORG_A', 'TEMPLATE_A', 'a', 'a1', '2', '2', true));
        bundle.incidentTemplates.add(incidentTemplate('ORG_B', 'TEMPLATE_B', 'b', 'b1', '2', '2', true));
        bundle.incidentTemplates.add(incidentTemplate(null, 'TEMPLATE_SHARED', 'shared', 'shared1', '3', '3', true));

        bundle.featureToggles.add(featureToggle(null, 'CASE_TO_INCIDENT_SYNC', true));
        bundle.featureToggles.add(featureToggle('ORG_A', 'CASE_TO_INCIDENT_SYNC', true));
        bundle.featureToggles.add(featureToggle('ORG_B', 'CASE_TO_INCIDENT_SYNC', true));
        bundle.featureToggles.add(featureToggle('ORG_B', 'COMMENT_SYNC', false));
        bundle.featureToggles.add(featureToggle('ORG_A', 'COMMENT_SYNC', true));

        bundle.endpointConfigs.add(endpointConfig('SNOW_US_PROD', 'ServiceNow_Named_Credential', '/api/now/table', 12000, true));
        bundle.endpointConfigs.add(endpointConfig('SNOW_EMEA_PROD', 'ServiceNow_Named_Credential', '/api/now/table', 15000, true));
        return bundle;
    }

    public static SN_Org_Config__mdt orgConfig(String orgKey, String defaultRequestType, String endpointKey, Boolean isActive, String businessUnit) {
        SN_Org_Config__mdt record = new SN_Org_Config__mdt();
        record.DeveloperName = String.isBlank(orgKey) ? 'GLOBAL' : orgKey;
        record.MasterLabel = record.DeveloperName;
        record.Org_Key__c = orgKey;
        record.Salesforce_Org_Id__c = '00D' + uniqueDigits(12);
        record.Business_Unit__c = businessUnit;
        record.Environment__c = 'TEST';
        record.Default_Request_Type__c = defaultRequestType;
        record.Endpoint_Config_Key__c = endpointKey;
        record.Is_Active__c = isActive;
        return record;
    }

    public static SN_Request_Type__mdt requestType(String orgKey, String requestTypeKey, String templateKey, String routingKey, Boolean isActive) {
        SN_Request_Type__mdt record = new SN_Request_Type__mdt();
        record.DeveloperName = (String.isBlank(orgKey) ? 'GLOBAL' : orgKey) + '_' + requestTypeKey;
        record.MasterLabel = requestTypeKey;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Source_Object__c = 'Case';
        record.Operation_Mode__c = 'Create Incident';
        record.Incident_Template_Key__c = templateKey;
        record.Routing_Key__c = routingKey;
        record.Is_Active__c = isActive;
        return record;
    }

    public static SN_Routing_Rule__mdt routingRule(String developerName, String orgKey, String requestTypeKey, String assignmentKey,
        Decimal priority, Boolean isDefault, String matchCriteria, Boolean isActive) {
        SN_Routing_Rule__mdt record = new SN_Routing_Rule__mdt();
        record.DeveloperName = developerName;
        record.MasterLabel = developerName;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Assignment_Target_Key__c = assignmentKey;
        record.Priority__c = priority;
        record.Is_Default__c = isDefault;
        record.Match_Criteria__c = matchCriteria;
        record.Is_Active__c = isActive;
        return record;
    }

    public static SN_Assignment_Target__mdt assignmentTarget(String orgKey, String key, String assignmentType, String externalId, Boolean isActive) {
        SN_Assignment_Target__mdt record = new SN_Assignment_Target__mdt();
        record.DeveloperName = (String.isBlank(orgKey) ? 'GLOBAL' : orgKey) + '_' + key;
        record.MasterLabel = key;
        record.Org_Key__c = orgKey;
        record.Assignment_Target_Key__c = key;
        record.Assignment_Type__c = assignmentType;
        record.External_Assignment_Id__c = externalId;
        record.Display_Name__c = key + ' Name';
        record.Is_Active__c = isActive;
        return record;
    }

    public static SN_Field_Mapping__mdt fieldMapping(String developerName, String orgKey, String requestTypeKey,
        String sourceFieldApi, String targetFieldApi, String strategy, String staticValue, Decimal sequence, Boolean isActive) {
        SN_Field_Mapping__mdt record = new SN_Field_Mapping__mdt();
        record.DeveloperName = developerName;
        record.MasterLabel = developerName;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Source_Field_API__c = sourceFieldApi;
        record.Target_Field_API__c = targetFieldApi;
        record.Transform_Strategy__c = strategy;
        record.Static_Value__c = staticValue;
        record.Sequence__c = sequence;
        record.Is_Active__c = isActive;
        return record;
    }

    public static SN_Feature_Toggle__mdt featureToggle(String orgKey, String featureKey, Boolean enabled) {
        SN_Feature_Toggle__mdt record = new SN_Feature_Toggle__mdt();
        record.DeveloperName = (String.isBlank(orgKey) ? 'GLOBAL' : orgKey) + '_' + featureKey;
        record.MasterLabel = featureKey;
        record.Org_Key__c = orgKey;
        record.Feature_Key__c = featureKey;
        record.Is_Enabled__c = enabled;
        record.Rollout_Group__c = 'TEST';
        record.Request_Type_Key__c = null;
        record.Is_Kill_Switch__c = false;
        record.Depends_On_Feature__c = null;
        record.Notes__c = 'Generated for tests';
        return record;
    }

    public static SN_Incident_Template__mdt incidentTemplate(String orgKey, String templateKey, String category, String subcategory, String impact, String urgency, Boolean isActive) {
        SN_Incident_Template__mdt record = new SN_Incident_Template__mdt();
        record.DeveloperName = (String.isBlank(orgKey) ? 'GLOBAL' : orgKey) + '_' + templateKey;
        record.MasterLabel = templateKey;
        record.Org_Key__c = orgKey;
        record.Incident_Template_Key__c = templateKey;
        record.Category__c = category;
        record.Subcategory__c = subcategory;
        record.Impact__c = impact;
        record.Urgency__c = urgency;
        record.Short_Description_Template__c = 'Template ' + templateKey;
        record.Is_Active__c = isActive;
        return record;
    }

    public static SN_Endpoint_Config__mdt endpointConfig(String key, String namedCredential, String basePath, Decimal timeoutMs, Boolean isActive) {
        SN_Endpoint_Config__mdt record = new SN_Endpoint_Config__mdt();
        record.DeveloperName = key;
        record.MasterLabel = key;
        record.Endpoint_Config_Key__c = key;
        record.Named_Credential__c = namedCredential;
        record.Base_Path__c = basePath;
        record.Timeout_Ms__c = timeoutMs;
        record.Is_Active__c = isActive;
        return record;
    }

    public static String uniqueSuffix() {
        return String.valueOf(Crypto.getRandomInteger()).replace('-', '');
    }

    private static String uniqueDigits(Integer length) {
        String digits = String.valueOf(Math.abs(Crypto.getRandomInteger())) + String.valueOf(DateTime.now().getTime());
        while (digits.length() < length) {
            digits += '0';
        }
        return digits.substring(0, length);
    }
}
