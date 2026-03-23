@IsTest
private class SN_IntegrationOrchestratorTest {
    private class ToggleOnGateway implements SN_IntegrationOrchestrator.IFeatureToggleGateway {
        public Boolean isEnabled(String featureKey, String orgKey) { return true; }
    }
    private class ConfigGateway implements SN_IntegrationOrchestrator.IConfigurationGateway {
        public SN_ConfigService.OrgConfig getOrgConfig(String orgKey) {
            SN_Org_Config__mdt record = new SN_Org_Config__mdt();
            record.DeveloperName = orgKey;
            record.MasterLabel = orgKey;
            record.Org_Key__c = orgKey;
            record.Is_Active__c = true;
            record.Default_Request_Type__c = 'INCIDENT_STANDARD';
            return new SN_ConfigService.OrgConfig(record);
        }
        public SN_ConfigService.RequestTypeConfig getRequestType(String orgKey, String requestTypeKey) {
            SN_Request_Type__mdt record = new SN_Request_Type__mdt();
            record.DeveloperName = String.isBlank(requestTypeKey) ? 'INCIDENT_STANDARD' : requestTypeKey;
            record.MasterLabel = record.DeveloperName;
            record.Org_Key__c = orgKey;
            record.Request_Type_Key__c = record.DeveloperName;
            record.Source_Object__c = 'Case';
            record.Operation_Mode__c = 'Create Incident';
            record.Routing_Key__c = 'CASE_ROUTE';
            record.Is_Active__c = true;
            return new SN_ConfigService.RequestTypeConfig(record);
        }
    }
    private class MappingGateway implements SN_IntegrationOrchestrator.IFieldMappingGateway {
        public Map<String, Object> buildPayload(String orgKey, String requestTypeKey, Case caseRecord, Map<String, Object> relatedData) {
            return new Map<String, Object>{
                'short_description' => caseRecord.Subject,
                'description' => caseRecord.Description
            };
        }
    }
    private class RoutingGateway implements SN_IntegrationOrchestrator.IRoutingGateway {
        public SN_RoutingService.RoutingOutcome resolve(SN_RoutingService.RoutingContext context) {
            SN_RoutingService.RoutingOutcome outcome = new SN_RoutingService.RoutingOutcome();
            outcome.assignmentTargetKey = 'US_TIER2';
            outcome.assignmentTarget = new SN_ConfigService.AssignmentTargetConfig(assignmentTargetRecord());
            return outcome;
        }
    }
    private class SuccessClient implements SN_IntegrationOrchestrator.IServiceNowGateway {
        public static Integer invocations = 0;
        public SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request) {
            invocations++;
            SN_ServiceNowClient.ResponseEnvelope response = new SN_ServiceNowClient.ResponseEnvelope();
            response.success = true;
            response.statusCode = 201;
            response.responseBody = '{"result":{"sys_id":"inc-1001"}}';
            response.safeSummary = 'statusCode=201';
            return response;
        }
    }
    private class RetryClient implements SN_IntegrationOrchestrator.IServiceNowGateway {
        public static Integer invocations = 0;
        public SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request) {
            invocations++;
            SN_ServiceNowClient.ResponseEnvelope response = new SN_ServiceNowClient.ResponseEnvelope();
            response.success = true;
            response.statusCode = 201;
            response.responseBody = '{"result":{"sys_id":"inc-2002"}}';
            response.safeSummary = 'statusCode=201';
            return response;
        }
    }

    @TestSetup
    static void setupData() {
        insert new Case(Subject = 'Printer issue', Description = 'Paper jam', Origin = 'Phone', Priority = 'Medium');
    }

    @IsTest
    static void skipsDuplicateExecutionAfterSuccessfulTransaction() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        configureDependencies(new SuccessClient());

        SN_IntegrationOrchestrator.RequestContext context = new SN_IntegrationOrchestrator.RequestContext();
        context.orgKey = 'US_HEALTHCARE_PROD';
        context.requestTypeKey = 'INCIDENT_STANDARD';
        context.businessContext = 'support';

        Test.startTest();
        SN_IntegrationOrchestrator.OrchestrationResult firstRun = SN_IntegrationOrchestrator.orchestrate(caseRecord.Id, context);
        SN_IntegrationOrchestrator.OrchestrationResult secondRun = SN_IntegrationOrchestrator.orchestrate(caseRecord.Id, context);
        Test.stopTest();

        System.assertEquals(false, firstRun.skippedDuplicate);
        System.assertEquals(true, secondRun.skippedDuplicate);
        System.assertEquals('inc-1001', secondRun.targetRecordId);
        System.assertEquals(1, SuccessClient.invocations);

        Integration_Transaction__c txn = [SELECT Status__c, TargetRecordId__c, RetryCount__c FROM Integration_Transaction__c WHERE Id = :firstRun.transactionId];
        System.assertEquals('Succeeded', txn.Status__c);
        System.assertEquals('inc-1001', txn.TargetRecordId__c);
        System.assertEquals(0, txn.RetryCount__c);
    }

    @IsTest
    static void reusesFailedTransactionForRetryExecution() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        configureDependencies(new RetryClient());
        String idempotencyKey = SN_IdempotencyService.buildKey(caseRecord.Id, 'createIncident', 'US_HEALTHCARE_PROD|INCIDENT_STANDARD|support');
        Integration_Transaction__c failedTxn = new Integration_Transaction__c(
            IdempotencyKey__c = idempotencyKey,
            CorrelationId__c = 'corr-old',
            SourceSystem__c = 'Salesforce',
            Operation__c = 'createIncident',
            SourceRecordId__c = caseRecord.Id,
            RequestType__c = 'INCIDENT_STANDARD',
            SalesforceOrgCode__c = 'US_HEALTHCARE_PROD',
            Status__c = 'Failed',
            RetryCount__c = 0,
            StartedAt__c = System.now().addMinutes(-5)
        );
        insert failedTxn;

        SN_IntegrationOrchestrator.RequestContext context = new SN_IntegrationOrchestrator.RequestContext();
        context.orgKey = 'US_HEALTHCARE_PROD';
        context.requestTypeKey = 'INCIDENT_STANDARD';
        context.businessContext = 'support';

        Test.startTest();
        SN_IntegrationOrchestrator.OrchestrationResult retryRun = SN_IntegrationOrchestrator.orchestrate(caseRecord.Id, context);
        Test.stopTest();

        System.assertEquals(true, retryRun.retryExecution);
        System.assertEquals(false, retryRun.skippedDuplicate);
        System.assertEquals(1, RetryClient.invocations);

        Integration_Transaction__c txn = [SELECT Status__c, TargetRecordId__c, RetryCount__c FROM Integration_Transaction__c WHERE Id = :failedTxn.Id];
        System.assertEquals('Succeeded', txn.Status__c);
        System.assertEquals('inc-2002', txn.TargetRecordId__c);
        System.assertEquals(1, txn.RetryCount__c);
    }

    private static void configureDependencies(SN_IntegrationOrchestrator.IServiceNowGateway serviceNowGateway) {
        SN_IntegrationOrchestrator.resetDependencies();
        SuccessClient.invocations = 0;
        RetryClient.invocations = 0;
        SN_IntegrationOrchestrator.featureToggleGateway = new ToggleOnGateway();
        SN_IntegrationOrchestrator.configurationGateway = new ConfigGateway();
        SN_IntegrationOrchestrator.fieldMappingGateway = new MappingGateway();
        SN_IntegrationOrchestrator.routingGateway = new RoutingGateway();
        SN_IntegrationOrchestrator.serviceNowGateway = serviceNowGateway;
    }

    private static SN_Assignment_Target__mdt assignmentTargetRecord() {
        SN_Assignment_Target__mdt record = new SN_Assignment_Target__mdt();
        record.DeveloperName = 'US_TIER2';
        record.MasterLabel = 'US_TIER2';
        record.Org_Key__c = 'US_HEALTHCARE_PROD';
        record.Assignment_Target_Key__c = 'US_TIER2';
        record.Assignment_Type__c = 'Group';
        record.External_Assignment_Id__c = 'group-sys-id';
        record.Display_Name__c = 'Tier 2';
        record.Is_Active__c = true;
        return record;
    }
}
