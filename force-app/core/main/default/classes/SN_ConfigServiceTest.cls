@IsTest
private class SN_ConfigServiceTest {
    @TestSetup
    static void setupData() {
        SN_ConfigService.setTestData(
            new List<SN_Org_Config__mdt>{
                orgConfig('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD'),
                orgConfig('EMEA_SUPPORT_PROD', 'INCIDENT_EMEA')
            },
            new List<SN_Request_Type__mdt>{
                requestType('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'US_CASE_ROUTING'),
                requestType(null, 'INCIDENT_SHARED', 'GLOBAL_ROUTING')
            },
            new List<SN_Routing_Rule__mdt>{
                routingRule('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'US_TIER2', 20, false),
                routingRule('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'US_DEFAULT', 50, true),
                routingRule(null, 'INCIDENT_SHARED', 'GLOBAL_TARGET', 100, true)
            },
            new List<SN_Assignment_Target__mdt>{
                assignmentTarget('US_HEALTHCARE_PROD', 'US_TIER2', 'Group'),
                assignmentTarget('US_HEALTHCARE_PROD', 'US_DEFAULT', 'Queue'),
                assignmentTarget(null, 'GLOBAL_TARGET', 'Queue')
            }
        );

        SN_FeatureToggleService.setTestData(new List<SN_Feature_Toggle__mdt>{
            featureToggle(null, 'GLOBAL_SYNC', true),
            featureToggle('US_HEALTHCARE_PROD', 'ENHANCED_MAPPING', true),
            featureToggle('EMEA_SUPPORT_PROD', 'ENHANCED_MAPPING', false)
        });
    }

    @IsTest
    static void returnsTypedOrgAndRequestTypeWrappers() {
        SN_ConfigService.OrgConfig orgConfig = SN_ConfigService.getOrgConfigWrapper('US_HEALTHCARE_PROD');
        SN_ConfigService.RequestTypeConfig requestType = SN_ConfigService.getRequestTypeConfigWrapper('US_HEALTHCARE_PROD', null);

        System.assertEquals('US_HEALTHCARE_PROD', orgConfig.orgKey);
        System.assertEquals('INCIDENT_STANDARD', requestType.requestTypeKey);
        System.assertEquals('US_CASE_ROUTING', requestType.routingKey);
    }

    @IsTest
    static void combinesRoutingAndAssignmentTargetsIntoBundle() {
        SN_ConfigService.ConfigBundle bundle = SN_ConfigService.getBundle('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');

        System.assertEquals('US_HEALTHCARE_PROD', bundle.orgConfig.orgKey);
        System.assertEquals(2, bundle.routingRules.size());
        System.assertEquals('US_TIER2', bundle.routingRules[0].assignmentTargetKey);
        System.assertEquals('Group', bundle.assignmentTargetsByKey.get('US_TIER2').assignmentType);
    }

    @IsTest
    static void supportsGlobalFallbackForRequestTypesAndToggles() {
        SN_ConfigService.RequestTypeConfig requestType = SN_ConfigService.getRequestTypeConfigWrapper('EMEA_SUPPORT_PROD', 'INCIDENT_SHARED');

        System.assertEquals('GLOBAL_ROUTING', requestType.routingKey);
        System.assertEquals(true, SN_FeatureToggleService.isEnabled('GLOBAL_SYNC', 'EMEA_SUPPORT_PROD'));
        System.assertEquals(false, SN_FeatureToggleService.isEnabled('ENHANCED_MAPPING', 'EMEA_SUPPORT_PROD'));
    }

    private static SN_Org_Config__mdt orgConfig(String orgKey, String defaultRequestType) {
        SN_Org_Config__mdt record = new SN_Org_Config__mdt();
        record.DeveloperName = orgKey;
        record.MasterLabel = orgKey;
        record.Org_Key__c = orgKey;
        record.Default_Request_Type__c = defaultRequestType;
        record.Is_Active__c = true;
        record.Endpoint_Config_Key__c = orgKey + '_ENDPOINT';
        return record;
    }

    private static SN_Request_Type__mdt requestType(String orgKey, String requestTypeKey, String routingKey) {
        SN_Request_Type__mdt record = new SN_Request_Type__mdt();
        record.DeveloperName = requestTypeKey;
        record.MasterLabel = requestTypeKey;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Source_Object__c = 'Case';
        record.Operation_Mode__c = 'Create Incident';
        record.Routing_Key__c = routingKey;
        record.Is_Active__c = true;
        return record;
    }

    private static SN_Routing_Rule__mdt routingRule(String orgKey, String requestTypeKey, String assignmentKey, Decimal priority, Boolean isDefault) {
        SN_Routing_Rule__mdt record = new SN_Routing_Rule__mdt();
        record.DeveloperName = requestTypeKey + '_' + assignmentKey;
        record.MasterLabel = requestTypeKey + ' ' + assignmentKey;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Assignment_Target_Key__c = assignmentKey;
        record.Priority__c = priority;
        record.Is_Default__c = isDefault;
        record.Is_Active__c = true;
        return record;
    }

    private static SN_Assignment_Target__mdt assignmentTarget(String orgKey, String assignmentKey, String assignmentType) {
        SN_Assignment_Target__mdt record = new SN_Assignment_Target__mdt();
        record.DeveloperName = assignmentKey;
        record.MasterLabel = assignmentKey;
        record.Org_Key__c = orgKey;
        record.Assignment_Target_Key__c = assignmentKey;
        record.Assignment_Type__c = assignmentType;
        record.External_Assignment_Id__c = assignmentKey + '_EXT';
        record.Display_Name__c = assignmentKey + ' Name';
        record.Is_Active__c = true;
        return record;
    }

    private static SN_Feature_Toggle__mdt featureToggle(String orgKey, String featureKey, Boolean enabled) {
        SN_Feature_Toggle__mdt record = new SN_Feature_Toggle__mdt();
        record.DeveloperName = featureKey + (orgKey == null ? '_GLOBAL' : '_' + orgKey);
        record.MasterLabel = featureKey;
        record.Org_Key__c = orgKey;
        record.Feature_Key__c = featureKey;
        record.Is_Enabled__c = enabled;
        return record;
    }
}
