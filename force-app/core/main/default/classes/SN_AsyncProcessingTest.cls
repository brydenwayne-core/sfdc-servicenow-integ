@IsTest
private class SN_AsyncProcessingTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void incidentQueueableProcessesUsingSharedFactories() {
        Case caseRecord = TestCaseFactory.createCaseForOrg('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');
        IntegrationTestUtils.configureOrchestrator(MockServiceNowHttpResponse.createIncidentSuccess());

        Test.startTest();
        System.enqueueJob(new SN_IncidentSyncQueueable(caseRecord.Id, 'INCIDENT_STANDARD', 'US_HEALTHCARE_PROD', 'queueable submission flow'));
        Test.stopTest();

        Integration_Transaction__c transactionRecord = [
            SELECT Status__c, TargetRecordId__c, RequestType__c
            FROM Integration_Transaction__c
            WHERE SourceRecordId__c = :caseRecord.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Succeeded', transactionRecord.Status__c);
        System.assertEquals('inc-1001', transactionRecord.TargetRecordId__c);
        System.assertEquals('INCIDENT_STANDARD', transactionRecord.RequestType__c);
    }

    @IsTest
    static void fileQueueableSupportsSuccessAndFailureMocks() {
        Case caseRecord = TestCaseFactory.createCaseForOrg('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');
        ContentVersion versionRecord = new ContentVersion(
            Title = 'intake-note',
            PathOnClient = 'intake-note.txt',
            VersionData = Blob.valueOf('hello world')
        );
        insert versionRecord;

        Test.setMock(HttpCalloutMock.class, MockServiceNowHttpResponse.fileSyncSuccess());
        Test.startTest();
        System.enqueueJob(new SN_FileSyncQueueable(caseRecord.Id, versionRecord.Id, 'inc-queue-1', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD'));
        Test.stopTest();

        Integration_Transaction__c successRecord = [
            SELECT Status__c, TargetRecordId__c, Operation__c
            FROM Integration_Transaction__c
            WHERE Operation__c = 'syncFile'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Succeeded', successRecord.Status__c);
        System.assertEquals('inc-queue-1', successRecord.TargetRecordId__c);

        ContentVersion failingVersion = new ContentVersion(
            Title = 'intake-failure',
            PathOnClient = 'intake-failure.txt',
            VersionData = Blob.valueOf('hello again')
        );
        insert failingVersion;
        Test.setMock(HttpCalloutMock.class, MockServiceNowErrorResponse.fileSyncFailure());
        try {
            Test.startTest();
            System.enqueueJob(new SN_FileSyncQueueable(caseRecord.Id, failingVersion.Id, 'inc-queue-2', 'US_HEALTHCARE_PROD', 'INCIDENT_STANDARD'));
            Test.stopTest();
            System.assert(false, 'Expected file sync failure');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('File synchronization failed'));
        }
    }

    @IsTest
    static void retryQueueableReplaysFailedTransaction() {
        Case caseRecord = TestCaseFactory.createCaseForOrg('US_HEALTHCARE_PROD', 'INCIDENT_STANDARD');
        IntegrationTestUtils.configureOrchestrator(MockServiceNowHttpResponse.createIncidentSuccess());
        String idempotencyKey = SN_IdempotencyService.buildKey(caseRecord.Id, 'createIncident', 'US_HEALTHCARE_PROD|INCIDENT_STANDARD|retry path');
        Integration_Transaction__c failedRecord = new Integration_Transaction__c(
            IdempotencyKey__c = idempotencyKey,
            CorrelationId__c = 'corr-old',
            SourceSystem__c = 'Salesforce',
            Operation__c = 'createIncident',
            SourceRecordId__c = caseRecord.Id,
            RequestType__c = 'INCIDENT_STANDARD',
            SalesforceOrgCode__c = 'US_HEALTHCARE_PROD',
            Status__c = 'Failed',
            RetryCount__c = 0,
            StartedAt__c = System.now().addMinutes(-10)
        );
        insert failedRecord;

        Test.startTest();
        System.enqueueJob(new SN_TransactionRetryQueueable(failedRecord.Id));
        Test.stopTest();

        Integration_Transaction__c refreshed = [SELECT Status__c, RetryCount__c, TargetRecordId__c FROM Integration_Transaction__c WHERE Id = :failedRecord.Id];
        System.assertEquals('Succeeded', refreshed.Status__c);
        System.assertEquals(1, refreshed.RetryCount__c);
        System.assertEquals('inc-1001', refreshed.TargetRecordId__c);
    }
}
