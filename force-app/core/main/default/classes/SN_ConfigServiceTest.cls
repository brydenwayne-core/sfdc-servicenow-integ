@IsTest
private class SN_ConfigServiceTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void returnsTypedWrappersAndBundleFromSharedMetadata() {
        SN_ConfigService.OrgConfig orgConfig = SN_ConfigService.getOrgConfigWrapper('US_HEALTHCARE_PROD');
        SN_ConfigService.RequestTypeConfig requestType = SN_ConfigService.getRequestTypeConfigWrapper('US_HEALTHCARE_PROD', null);
        SN_ConfigService.ConfigBundle bundle = SN_ConfigService.getBundle('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');

        System.assertEquals('US_HEALTHCARE_PROD', orgConfig.orgKey);
        System.assertEquals('INCIDENT_STANDARD', requestType.requestTypeKey);
        System.assertEquals('TEMPLATE_STANDARD', requestType.incidentTemplateKey);
        System.assertEquals(2, bundle.routingRules.size());
        System.assertEquals('group-us-tier2', bundle.assignmentTargetsByKey.get('US_TIER2').externalAssignmentId);
    }

    @IsTest
    static void supportsGlobalRequestTypeFallbackAcrossOrgs() {
        SN_ConfigService.RequestTypeConfig requestType = SN_ConfigService.getRequestTypeConfigWrapper('ORG_B', 'REQUEST_SHARED');
        List<SN_ConfigService.RoutingRuleConfig> routingRules = SN_ConfigService.getRoutingRules('ORG_B', 'REQUEST_SHARED');

        System.assertEquals('TEMPLATE_SHARED', requestType.incidentTemplateKey);
        System.assertEquals(1, routingRules.size());
        System.assertEquals('GLOBAL_TARGET', routingRules[0].assignmentTargetKey);
    }

    @IsTest
    static void ignoresInactiveOrgConfiguration() {
        System.assertEquals(null, SN_ConfigService.getOrgConfigWrapper('ORG_DISABLED'));
    }
}
