@IsTest
private class SN_FieldMappingServiceTest {
    @TestSetup
    static void setupData() {
        SN_FieldMappingService.setTestData(new List<SN_Field_Mapping__mdt>{
            mapping('GLOBAL_CATEGORY', null, 'INCIDENT_STANDARD', null, 'category', 'Static Value', 'general', 1),
            mapping('US_SHORT_DESCRIPTION', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'Case.Subject', 'short_description', 'Trim', null, 2),
            mapping('US_DESCRIPTION', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'Case.Description', 'description', 'Direct', null, 3),
            mapping('US_ACCOUNT_NAME', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', 'Account.Name', 'u_account_name', 'Uppercase', null, 4),
            mapping('EMEA_SHORT_DESCRIPTION', 'EMEA_SUPPORT_PROD', 'INCIDENT_EMEA', 'Case.Subject', 'short_description', 'Lowercase', null, 1)
        });
    }

    @IsTest
    static void resolvesMappingsByOrgAndRequestType() {
        List<SN_Field_Mapping__mdt> usMappings = SN_FieldMappingService.getActiveMappings('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');
        List<SN_FieldMappingService.FieldMappingRule> emeaMappings = SN_FieldMappingService.getActiveMappingRules('EMEA_SUPPORT_PROD', 'INCIDENT_EMEA');

        System.assertEquals(4, usMappings.size());
        System.assertEquals(1, emeaMappings.size());
        System.assertEquals('short_description', emeaMappings[0].targetFieldApi);
    }

    @IsTest
    static void buildsIncidentPayloadWithRelatedDataAndTransforms() {
        Case caseRecord = new Case(Subject = '  MRI issue  ', Description = 'Scanner is offline');
        Map<String, Object> relatedData = new Map<String, Object>{
            'Account' => new Map<String, Object>{ 'Name' => 'North Hospital' }
        };

        SN_FieldMappingService.IncidentPayload payload = SN_FieldMappingService.buildIncidentPayload(
            'US_HEALTHCARE_PROD',
            'INCIDENT_STANDARD',
            caseRecord,
            relatedData
        );

        System.assertEquals('general', payload.fields.get('category'));
        System.assertEquals('MRI issue', payload.fields.get('short_description'));
        System.assertEquals('Scanner is offline', payload.fields.get('description'));
        System.assertEquals('NORTH HOSPITAL', payload.fields.get('u_account_name'));
    }

    @IsTest
    static void supportsDifferentRequestTypesAcrossOrgs() {
        Case caseRecord = new Case(Subject = 'Clinical escalation');

        SN_FieldMappingService.IncidentPayload payload = SN_IncidentPayloadBuilder.buildIncidentPayload(
            'EMEA_SUPPORT_PROD',
            'INCIDENT_EMEA',
            caseRecord,
            null
        );

        System.assertEquals('clinical escalation', payload.fields.get('short_description'));
        System.assertEquals(false, payload.fields.containsKey('description'));
    }

    private static SN_Field_Mapping__mdt mapping(String developerName, String orgKey, String requestTypeKey,
        String sourceFieldApi, String targetFieldApi, String strategy, String staticValue, Decimal sequence) {
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
        record.Is_Active__c = true;
        return record;
    }
}
