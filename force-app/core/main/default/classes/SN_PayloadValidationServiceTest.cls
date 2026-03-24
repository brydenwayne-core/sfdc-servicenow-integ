@IsTest
private class SN_PayloadValidationServiceTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void returnsErrorForMissingRequiredFields() {
        Map<String, Object> payload = new Map<String, Object>{ 'description' => 'safe' };
        SN_PayloadValidationService.ValidationResult result = SN_PayloadValidationService.validateIncidentCreate(
            'US_HEALTHCARE_PROD',
            'INCIDENT_STANDARD',
            payload
        );
        System.assertEquals(false, result.valid);
        System.assertEquals('REQUIRED_FIELD_MISSING', result.code);
    }

    @IsTest
    static void returnsErrorForUnsupportedRequestTypeAndMissingMappings() {
        SN_PayloadValidationService.ValidationResult unsupported = SN_PayloadValidationService.validateIncidentCreate(
            'US_HEALTHCARE_PROD',
            'DOES_NOT_EXIST',
            new Map<String, Object>{ 'short_description' => 'safe', 'u_salesforce_case_id' => '5001' }
        );
        System.assertEquals(false, unsupported.valid);
        System.assertEquals('REQUEST_TYPE_UNSUPPORTED', unsupported.code);

        SN_PayloadValidationService.ValidationResult incomplete = SN_PayloadValidationService.validateIncidentCreate(
            'US_HEALTHCARE_PROD',
            'REQUEST_SHARED',
            new Map<String, Object>{ 'short_description' => 'safe', 'u_salesforce_case_id' => '5001' }
        );
        System.assertEquals(false, incomplete.valid);
        System.assertEquals('MAPPING_INCOMPLETE', incomplete.code);
    }
}
