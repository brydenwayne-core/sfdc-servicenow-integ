@IsTest
private class SN_FieldMappingServiceTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void buildsIncidentPayloadFromSharedFactories() {
        Case caseRecord = TestCaseFactory.createHighPriorityIncidentCase();

        SN_FieldMappingService.IncidentPayload payload = SN_FieldMappingService.buildIncidentPayload(
            'US_HEALTHCARE_PROD',
            'INCIDENT_STANDARD',
            caseRecord,
            null
        );

        System.assertEquals('general', payload.fields.get('category'));
        System.assertEquals('MRI outage', payload.fields.get('short_description'));
        System.assertEquals('Scanner is unavailable', payload.fields.get('description'));
        System.assertEquals('high', payload.fields.get('priority'));
    }

    @IsTest
    static void supportsOrgSpecificMappingVariation() {
        Case orgACase = TestCaseFactory.createCaseForOrg('ORG_A', 'REQUEST_X', new Map<String, Object>{ 'Subject' => 'Escalation for labs' }, true);
        Case orgBCase = TestCaseFactory.createCaseForOrg('ORG_B', 'REQUEST_Y', new Map<String, Object>{ 'Subject' => 'Escalation for clinics' }, true);

        SN_FieldMappingService.IncidentPayload orgAPayload = SN_FieldMappingService.buildIncidentPayload('ORG_A', 'REQUEST_X', orgACase, null);
        SN_FieldMappingService.IncidentPayload orgBPayload = SN_FieldMappingService.buildIncidentPayload('ORG_B', 'REQUEST_Y', orgBCase, null);

        System.assertEquals('ESCALATION FOR LABS', orgAPayload.fields.get('short_description'));
        System.assertEquals('escalation for clinics', orgBPayload.fields.get('short_description'));
        System.assertEquals('REQUEST_Y', orgBPayload.fields.get('u_request_type'));
    }
}
