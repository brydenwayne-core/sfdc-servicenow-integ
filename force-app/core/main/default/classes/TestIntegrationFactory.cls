@IsTest
public with sharing class TestIntegrationFactory {
    public static Integration_Transaction__c createTransaction(String status) {
        return createTransaction(status, null, true);
    }

    public static Integration_Transaction__c createTransaction(String status, Map<String, Object> overrides, Boolean doInsert) {
        Case caseRecord = TestCaseFactory.createCaseForOrg('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');
        Integration_Transaction__c transactionRecord = new Integration_Transaction__c(
            CorrelationId__c = 'corr-' + TestDataFactory.uniqueSuffix(),
            IdempotencyKey__c = 'idem-' + TestDataFactory.uniqueSuffix(),
            SourceSystem__c = 'Salesforce',
            Operation__c = 'createIncident',
            SourceRecordId__c = caseRecord.Id,
            RequestType__c = 'INCIDENT_STANDARD',
            SalesforceOrgCode__c = 'US_HEALTHCARE_PROD',
            BusinessUnit__c = 'Healthcare East',
            SourceObjectApiName__c = 'Case',
            SourceRecordLabel__c = caseRecord.CaseNumber,
            Status__c = String.isBlank(status) ? 'Queued' : status,
            StartedAt__c = System.now().addMinutes(-5),
            RetryCount__c = 0
        );
        if (overrides != null) {
            for (String fieldName : overrides.keySet()) {
                transactionRecord.put(fieldName, overrides.get(fieldName));
            }
        }
        if (doInsert) {
            insert transactionRecord;
        }
        return transactionRecord;
    }
}
