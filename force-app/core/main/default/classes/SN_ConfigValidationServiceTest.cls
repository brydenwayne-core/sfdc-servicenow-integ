@IsTest
private class SN_ConfigValidationServiceTest {
    @IsTest
    static void returnsValidReportForBaselineConfiguration() {
        IntegrationTestUtils.applyBaselineMetadata();
        SN_ConfigValidationService.ValidationReport report = SN_ConfigValidationService.validateAll();
        System.assertEquals(true, report.isValid);
    }
    @IsTest
    static void detectsInvalidConfigurationPatterns() {
        TestDataFactory.MetadataBundle bundle = TestDataFactory.createBaselineMetadata();
        bundle.orgConfigs.clear();
        bundle.requestTypes[0].Incident_Template_Key__c = 'MISSING_TEMPLATE';
        bundle.routingRules[0].Assignment_Target_Key__c = 'UNKNOWN_TARGET';
        bundle.fieldMappings.add(TestDataFactory.fieldMapping('DUP_TARGET', 'ORG_A', 'REQUEST_X', 'Case.Description', 'short_description', 'Trim', null, 2, true));
        new MockConfigProvider(bundle).apply();
        SN_ConfigValidationService.ValidationReport report = SN_ConfigValidationService.validateAll();
        System.assertEquals(false, report.isValid);
        System.assert(report.toAdminSummary().contains('ORG_CONFIG_MISSING'));
        System.assert(report.toAdminSummary().contains('ROUTING_TARGET_INVALID'));
        System.assert(report.toAdminSummary().contains('FIELD_MAPPING_CONFLICT'));
        System.assert(report.toAdminSummary().contains('INCIDENT_TEMPLATE_MISSING'));
    }
}
