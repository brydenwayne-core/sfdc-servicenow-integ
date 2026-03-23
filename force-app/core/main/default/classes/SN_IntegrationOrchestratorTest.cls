@IsTest
private class SN_IntegrationOrchestratorTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void orchestratesCaseSubmissionUsingScenarioFactory() {
        TestScenarioFactory.Scenario scenario = TestScenarioFactory.createOrgAHighPriorityRequestTypeX();
        IntegrationTestUtils.configureOrchestrator(MockServiceNowHttpResponse.createIncidentSuccess());

        Test.startTest();
        SN_IntegrationOrchestrator.OrchestrationResult result = SN_IntegrationOrchestrator.orchestrate(
            scenario.caseRecord.Id,
            IntegrationTestUtils.requestContext(scenario.orgKey, scenario.requestTypeKey, scenario.businessContext)
        );
        Test.stopTest();

        Integration_Transaction__c transactionRecord = [
            SELECT Status__c, TargetRecordId__c, Safe_Request_Summary__c, Safe_Response_Summary__c
            FROM Integration_Transaction__c
            WHERE Id = :result.transactionId
        ];
        ServiceNow_Incident_Link__c linkRecord = [
            SELECT ServiceNow_Incident_Id__c, Link_Status__c, Salesforce_Org_Code__c
            FROM ServiceNow_Incident_Link__c
            WHERE Integration_Transaction__c = :result.transactionId
            LIMIT 1
        ];

        System.assertEquals('Succeeded', transactionRecord.Status__c);
        System.assertEquals('inc-1001', transactionRecord.TargetRecordId__c);
        System.assertEquals('inc-1001', linkRecord.ServiceNow_Incident_Id__c);
        System.assertEquals('Active', linkRecord.Link_Status__c);
        IntegrationTestUtils.assertHealthcareSafeLogging(transactionRecord);
    }

    @IsTest
    static void skipsDuplicateIdempotentSubmission() {
        TestScenarioFactory.Scenario scenario = TestScenarioFactory.createDuplicateIdempotentSubmission();
        IntegrationTestUtils.configureOrchestrator(MockServiceNowHttpResponse.createIncidentSuccess());
        SN_IntegrationOrchestrator.RequestContext context = IntegrationTestUtils.requestContext(
            scenario.orgKey,
            scenario.requestTypeKey,
            scenario.businessContext
        );

        Test.startTest();
        SN_IntegrationOrchestrator.OrchestrationResult firstRun = SN_IntegrationOrchestrator.orchestrate(scenario.caseRecord.Id, context);
        SN_IntegrationOrchestrator.OrchestrationResult secondRun = SN_IntegrationOrchestrator.orchestrate(scenario.caseRecord.Id, context);
        Test.stopTest();

        System.assertEquals(false, firstRun.skippedDuplicate);
        System.assertEquals(true, secondRun.skippedDuplicate);
        System.assertEquals('inc-1001', secondRun.targetRecordId);
    }

    @IsTest
    static void failsWhenFeatureToggleIsInactive() {
        TestScenarioFactory.Scenario scenario = TestScenarioFactory.createInactiveFeatureToggleScenario();
        IntegrationTestUtils.configureOrchestrator(MockServiceNowHttpResponse.createIncidentSuccess());

        SN_IntegrationOrchestrator.RequestContext context = IntegrationTestUtils.requestContext(
            scenario.orgKey,
            scenario.requestTypeKey,
            scenario.businessContext
        );
        context.featureKey = scenario.featureKey;

        try {
            SN_IntegrationOrchestrator.orchestrate(scenario.caseRecord.Id, context);
            System.assert(false, 'Expected feature toggle exception');
        } catch (SN_IntegrationOrchestrator.OrchestrationException ex) {
            System.assert(ex.getMessage().contains('disabled'));
        }
    }
}
