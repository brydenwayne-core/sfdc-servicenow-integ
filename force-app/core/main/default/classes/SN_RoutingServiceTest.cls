@IsTest
private class SN_RoutingServiceTest {
    @TestSetup
    static void setupData() {
        SN_ConfigService.setTestData(
            new List<SN_Org_Config__mdt>{ orgConfig('US_HEALTHCARE_PROD', 'REQ_STANDARD') },
            new List<SN_Request_Type__mdt>{ requestType('US_HEALTHCARE_PROD', 'REQ_STANDARD', 'TEMPLATE_DEFAULT') },
            new List<SN_Routing_Rule__mdt>{
                routingRule('RULE_HIGH', 'US_HEALTHCARE_PROD', 'REQ_STANDARD', 'GROUP_CARDIO', 10, false,
                    '{"when":{"category":"Clinical","region":"EAST"},"then":{"incidentTemplateKey":"TEMPLATE_CLINICAL","priorityBehavior":"P1_OVERRIDE","syncComments":true,"syncFiles":false}}'),
                routingRule('RULE_CONFLICT', 'US_HEALTHCARE_PROD', 'REQ_STANDARD', 'GROUP_NEURO', 20, false,
                    '{"when":{"category":"Clinical","region":"EAST"},"then":{"incidentTemplateKey":"TEMPLATE_NEURO","priorityBehavior":"P2_OVERRIDE"}}'),
                routingRule('RULE_INACTIVE', 'US_HEALTHCARE_PROD', 'REQ_STANDARD', 'GROUP_IGNORED', 5, false,
                    '{"when":{"category":"Ignored"},"then":{"incidentTemplateKey":"TEMPLATE_IGNORED"}}', false),
                routingRule('RULE_DEFAULT', 'US_HEALTHCARE_PROD', 'REQ_STANDARD', 'GROUP_DEFAULT', 99, true,
                    '{"then":{"incidentTemplateKey":"__REQUEST_TYPE_DEFAULT__","priorityBehavior":"REQUEST_TYPE","stopDownstreamProcessing":true,"syncComments":false,"syncFiles":true}}')
            },
            new List<SN_Assignment_Target__mdt>{
                assignmentTarget('US_HEALTHCARE_PROD', 'GROUP_CARDIO'),
                assignmentTarget('US_HEALTHCARE_PROD', 'GROUP_NEURO'),
                assignmentTarget('US_HEALTHCARE_PROD', 'GROUP_DEFAULT')
            }
        );
    }

    @IsTest
    static void selectsMatchingRuleAndAppliesMetadataDrivenOutputs() {
        SN_RoutingService.RoutingContext context = new SN_RoutingService.RoutingContext();
        context.orgKey = 'US_HEALTHCARE_PROD';
        context.requestTypeKey = 'REQ_STANDARD';
        context.category = 'Clinical';
        context.metadata.put('region', 'EAST');

        Test.startTest();
        try {
            SN_RoutingService.resolve(context);
            System.assert(false, 'Expected conflict exception.');
        } catch (SN_RoutingService.RoutingException ex) {
            System.assert(ex.getMessage().contains('Conflicting routing rules matched'));
        }
        Test.stopTest();
    }

    @IsTest
    static void ignoresInactiveRulesAndFallsBackToDefaultRule() {
        SN_ConfigService.setTestData(
            new List<SN_Org_Config__mdt>{ orgConfig('US_HEALTHCARE_PROD', 'REQ_STANDARD') },
            new List<SN_Request_Type__mdt>{ requestType('US_HEALTHCARE_PROD', 'REQ_STANDARD', 'TEMPLATE_DEFAULT') },
            new List<SN_Routing_Rule__mdt>{
                routingRule('RULE_INACTIVE', 'US_HEALTHCARE_PROD', 'REQ_STANDARD', 'GROUP_IGNORED', 5, false,
                    '{"when":{"category":"Ignored"},"then":{"incidentTemplateKey":"TEMPLATE_IGNORED"}}', false),
                routingRule('RULE_DEFAULT', 'US_HEALTHCARE_PROD', 'REQ_STANDARD', 'GROUP_DEFAULT', 99, true,
                    '{"then":{"incidentTemplateKey":"__REQUEST_TYPE_DEFAULT__","priorityBehavior":"REQUEST_TYPE","stopDownstreamProcessing":true,"syncComments":false,"syncFiles":true}}')
            },
            new List<SN_Assignment_Target__mdt>{ assignmentTarget('US_HEALTHCARE_PROD', 'GROUP_DEFAULT') }
        );

        SN_RoutingService.RoutingContext context = new SN_RoutingService.RoutingContext();
        context.orgKey = 'US_HEALTHCARE_PROD';
        context.requestTypeKey = 'REQ_STANDARD';
        context.category = 'Ignored';

        SN_RoutingService.RoutingOutcome outcome = SN_RoutingService.resolve(context);

        System.assertEquals('GROUP_DEFAULT', outcome.assignmentTargetKey);
        System.assertEquals('TEMPLATE_DEFAULT', outcome.incidentTemplateKey);
        System.assertEquals('REQUEST_TYPE', outcome.priorityBehavior);
        System.assertEquals(true, outcome.usedFallback);
        System.assertEquals(true, outcome.stopDownstreamProcessing);
        System.assertEquals(false, outcome.syncComments);
        System.assertEquals(true, outcome.syncFiles);
    }

    private static SN_Org_Config__mdt orgConfig(String orgKey, String defaultRequestType) {
        SN_Org_Config__mdt record = new SN_Org_Config__mdt();
        record.DeveloperName = orgKey;
        record.MasterLabel = orgKey;
        record.Org_Key__c = orgKey;
        record.Default_Request_Type__c = defaultRequestType;
        record.Endpoint_Config_Key__c = 'SNOW_US_PROD';
        record.Is_Active__c = true;
        return record;
    }

    private static SN_Request_Type__mdt requestType(String orgKey, String requestTypeKey, String templateKey) {
        SN_Request_Type__mdt record = new SN_Request_Type__mdt();
        record.DeveloperName = requestTypeKey;
        record.MasterLabel = requestTypeKey;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Incident_Template_Key__c = templateKey;
        record.Is_Active__c = true;
        return record;
    }

    private static SN_Routing_Rule__mdt routingRule(String devName, String orgKey, String requestTypeKey, String assignmentKey,
        Decimal priority, Boolean isDefault, String matchCriteria) {
        return routingRule(devName, orgKey, requestTypeKey, assignmentKey, priority, isDefault, matchCriteria, true);
    }

    private static SN_Routing_Rule__mdt routingRule(String devName, String orgKey, String requestTypeKey, String assignmentKey,
        Decimal priority, Boolean isDefault, String matchCriteria, Boolean isActive) {
        SN_Routing_Rule__mdt record = new SN_Routing_Rule__mdt();
        record.DeveloperName = devName;
        record.MasterLabel = devName;
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Assignment_Target_Key__c = assignmentKey;
        record.Priority__c = priority;
        record.Is_Default__c = isDefault;
        record.Match_Criteria__c = matchCriteria;
        record.Is_Active__c = isActive;
        return record;
    }

    private static SN_Assignment_Target__mdt assignmentTarget(String orgKey, String assignmentKey) {
        SN_Assignment_Target__mdt record = new SN_Assignment_Target__mdt();
        record.DeveloperName = assignmentKey;
        record.MasterLabel = assignmentKey;
        record.Org_Key__c = orgKey;
        record.Assignment_Target_Key__c = assignmentKey;
        record.Assignment_Type__c = 'Group';
        record.External_Assignment_Id__c = assignmentKey + '_EXT';
        record.Display_Name__c = assignmentKey;
        record.Is_Active__c = true;
        return record;
    }
}
