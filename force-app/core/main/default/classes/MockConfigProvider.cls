@IsTest
public with sharing class MockConfigProvider implements SN_IntegrationOrchestrator.IConfigurationGateway {
    private TestDataFactory.MetadataBundle bundle;

    public MockConfigProvider() {
        this(TestDataFactory.createBaselineMetadata());
    }

    public MockConfigProvider(TestDataFactory.MetadataBundle bundle) {
        this.bundle = bundle == null ? TestDataFactory.createBaselineMetadata() : bundle;
    }

    public void apply() {
        SN_ConfigService.setExtendedTestData(bundle.orgConfigs, bundle.requestTypes, bundle.routingRules, bundle.assignmentTargets, bundle.incidentTemplates, bundle.endpointConfigs);
        SN_FieldMappingService.setTestData(bundle.fieldMappings);
        SN_FeatureToggleService.setTestData(bundle.featureToggles);
        SN_ServiceNowClient.setEndpointConfigTestData(bundle.endpointConfigs);
    }

    public SN_ConfigService.OrgConfig getOrgConfig(String orgKey) {
        apply();
        return SN_ConfigService.getOrgConfigWrapper(orgKey);
    }

    public SN_ConfigService.RequestTypeConfig getRequestType(String orgKey, String requestTypeKey) {
        apply();
        return SN_ConfigService.getRequestTypeConfigWrapper(orgKey, requestTypeKey);
    }
}
