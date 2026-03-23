@IsTest
private class SN_AsyncProcessingTest {
    private class ToggleOnGateway implements SN_IntegrationOrchestrator.IFeatureToggleGateway {
        public Boolean isEnabled(String featureKey, String orgKey) { return true; }
    }
    private class ConfigGateway implements SN_IntegrationOrchestrator.IConfigurationGateway {
        public SN_ConfigService.OrgConfig getOrgConfig(String orgKey) {
            SN_Org_Config__mdt record = new SN_Org_Config__mdt();
            record.DeveloperName = String.isBlank(orgKey) ? 'DEFAULT' : orgKey;
            record.MasterLabel = record.DeveloperName;
            record.Org_Key__c = record.DeveloperName;
            record.Is_Active__c = true;
            record.Default_Request_Type__c = 'INCIDENT_STANDARD';
            record.Endpoint_Config_Key__c = 'SNOW_US_PROD';
            return new SN_ConfigService.OrgConfig(record);
        }
        public SN_ConfigService.RequestTypeConfig getRequestType(String orgKey, String requestTypeKey) {
            SN_Request_Type__mdt record = new SN_Request_Type__mdt();
            record.DeveloperName = String.isBlank(requestTypeKey) ? 'INCIDENT_STANDARD' : requestTypeKey;
            record.MasterLabel = 'Standard Incident';
            record.Org_Key__c = String.isBlank(orgKey) ? 'DEFAULT' : orgKey;
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
            return new Map<String, Object>{ 'short_description' => caseRecord.Subject, 'description' => caseRecord.Description };
        }
    }
    private class RoutingGateway implements SN_IntegrationOrchestrator.IRoutingGateway {
        public SN_RoutingService.RoutingOutcome resolve(SN_RoutingService.RoutingContext context) {
            return null;
        }
    }
    private class IncidentMockGateway implements SN_IntegrationOrchestrator.IServiceNowGateway {
        public SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request) {
            SN_ServiceNowClient.ResponseEnvelope response = new SN_ServiceNowClient.ResponseEnvelope();
            response.success = true;
            response.statusCode = 201;
            response.responseBody = '{"result":{"sys_id":"inc-queue-1"}}';
            response.safeSummary = 'statusCode=201';
            return response;
        }
    }
    private class FileMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setBody('{"result":{"sys_id":"att-1"}}');
            return response;
        }
    }

    @TestSetup
    static void setupData() {
        insert new Case(Subject = 'Queueable incident', Description = 'Async please', Origin = 'Web', Priority = 'Medium');
        SN_ConfigService.setTestData(
            new List<SN_Org_Config__mdt>{ orgConfig('DEFAULT') },
            new List<SN_Request_Type__mdt>{ requestType('DEFAULT', 'INCIDENT_STANDARD') },
            new List<SN_Routing_Rule__mdt>(),
            new List<SN_Assignment_Target__mdt>()
        );
        SN_ServiceNowClient.setEndpointConfigTestData(new List<SN_Endpoint_Config__mdt>{ endpointConfig('SNOW_US_PROD') });
    }

    @IsTest
    static void incidentQueueableCreatesTransactionAndCompletes() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        SN_IntegrationOrchestrator.resetDependencies();
        SN_IntegrationOrchestrator.featureToggleGateway = new ToggleOnGateway();
        SN_IntegrationOrchestrator.configurationGateway = new ConfigGateway();
        SN_IntegrationOrchestrator.fieldMappingGateway = new MappingGateway();
        SN_IntegrationOrchestrator.routingGateway = new RoutingGateway();
        SN_IntegrationOrchestrator.serviceNowGateway = new IncidentMockGateway();

        Test.startTest();
        System.enqueueJob(new SN_IncidentSyncQueueable(caseRecord.Id, 'INCIDENT_STANDARD', 'DEFAULT', 'intakeSubmission'));
        Test.stopTest();

        Integration_Transaction__c transactionRecord = [
            SELECT Status__c, TargetRecordId__c, SourceRecordId__c, RequestType__c
            FROM Integration_Transaction__c
            WHERE SourceRecordId__c = :caseRecord.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Succeeded', transactionRecord.Status__c);
        System.assertEquals('inc-queue-1', transactionRecord.TargetRecordId__c);
        System.assertEquals('INCIDENT_STANDARD', transactionRecord.RequestType__c);
    }

    @IsTest
    static void fileQueueableSynchronizesContentVersionAndLogsSuccess() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        ContentVersion versionRecord = new ContentVersion(
            Title = 'intake-note',
            PathOnClient = 'intake-note.txt',
            VersionData = Blob.valueOf('hello world')
        );
        insert versionRecord;

        Test.setMock(HttpCalloutMock.class, new FileMock());
        Test.startTest();
        System.enqueueJob(new SN_FileSyncQueueable(caseRecord.Id, versionRecord.Id, 'inc-queue-1', 'DEFAULT', 'INCIDENT_STANDARD'));
        Test.stopTest();

        Integration_Transaction__c transactionRecord = [
            SELECT Status__c, TargetRecordId__c, Operation__c
            FROM Integration_Transaction__c
            WHERE TargetRecordId__c = 'inc-queue-1'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Succeeded', transactionRecord.Status__c);
        System.assertEquals('syncFile', transactionRecord.Operation__c);
    }

    @IsTest
    static void retryQueueableReplaysFailedTransactionSafely() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        SN_IntegrationOrchestrator.resetDependencies();
        SN_IntegrationOrchestrator.featureToggleGateway = new ToggleOnGateway();
        SN_IntegrationOrchestrator.configurationGateway = new ConfigGateway();
        SN_IntegrationOrchestrator.fieldMappingGateway = new MappingGateway();
        SN_IntegrationOrchestrator.routingGateway = new RoutingGateway();
        SN_IntegrationOrchestrator.serviceNowGateway = new IncidentMockGateway();

        Integration_Transaction__c failedRecord = new Integration_Transaction__c(
            IdempotencyKey__c = 'retry-key',
            CorrelationId__c = 'corr-old',
            SourceSystem__c = 'Salesforce',
            Operation__c = 'createIncident',
            SourceRecordId__c = caseRecord.Id,
            RequestType__c = 'INCIDENT_STANDARD',
            SalesforceOrgCode__c = 'DEFAULT',
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
        System.assertEquals('inc-queue-1', refreshed.TargetRecordId__c);
    }

    private static SN_Org_Config__mdt orgConfig(String orgKey) {
        SN_Org_Config__mdt record = new SN_Org_Config__mdt();
        record.DeveloperName = orgKey;
        record.MasterLabel = orgKey;
        record.Org_Key__c = orgKey;
        record.Is_Active__c = true;
        record.Default_Request_Type__c = 'INCIDENT_STANDARD';
        record.Endpoint_Config_Key__c = 'SNOW_US_PROD';
        return record;
    }

    private static SN_Request_Type__mdt requestType(String orgKey, String requestTypeKey) {
        SN_Request_Type__mdt record = new SN_Request_Type__mdt();
        record.DeveloperName = requestTypeKey;
        record.MasterLabel = 'Standard Incident';
        record.Org_Key__c = orgKey;
        record.Request_Type_Key__c = requestTypeKey;
        record.Source_Object__c = 'Case';
        record.Operation_Mode__c = 'Create Incident';
        record.Routing_Key__c = 'CASE_ROUTE';
        record.Is_Active__c = true;
        return record;
    }

    private static SN_Endpoint_Config__mdt endpointConfig(String key) {
        SN_Endpoint_Config__mdt record = new SN_Endpoint_Config__mdt();
        record.DeveloperName = key;
        record.MasterLabel = key;
        record.Endpoint_Config_Key__c = key;
        record.Named_Credential__c = 'ServiceNow_Named_Credential';
        record.Base_Path__c = '/api/now/table';
        record.Timeout_Ms__c = 12000;
        record.Is_Active__c = true;
        return record;
    }
}
