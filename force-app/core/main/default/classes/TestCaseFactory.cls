@IsTest
public with sharing class TestCaseFactory {
    public static Case createCaseForOrg(String orgCode, String requestType) {
        return createCaseForOrg(orgCode, requestType, null, true);
    }

    public static Case createCaseForOrg(String orgCode, String requestType, Map<String, Object> overrides, Boolean doInsert) {
        Account accountRecord = TestDataFactory.createAccount(true);
        Contact contactRecord = TestDataFactory.createContact(accountRecord.Id, true);
        Case caseRecord = new Case(
            AccountId = accountRecord.Id,
            ContactId = contactRecord.Id,
            Subject = orgCode + ' ' + requestType + ' issue',
            Description = 'Clinical workflow issue for ' + orgCode,
            Origin = 'Phone',
            Priority = 'Medium',
            Type = requestType,
            Status = 'New'
        );
        applyOverrides(caseRecord, overrides);
        if (doInsert) {
            insert caseRecord;
        }
        return caseRecord;
    }

    public static Case createHighPriorityIncidentCase() {
        return createCaseForOrg('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD', new Map<String, Object>{
            'Subject' => '  MRI outage  ',
            'Description' => 'Scanner is unavailable',
            'Priority' => 'High',
            'Origin' => 'Web',
            'Type' => 'Clinical'
        }, true);
    }

    private static void applyOverrides(SObject record, Map<String, Object> overrides) {
        if (overrides == null) {
            return;
        }
        for (String fieldName : overrides.keySet()) {
            record.put(fieldName, overrides.get(fieldName));
        }
    }
}
