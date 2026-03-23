@IsTest
private class SN_ServiceNowClientTest {
    private class MockResponder implements HttpCalloutMock {
        Integer statusCode;
        String body;
        String transactionId;
        MockResponder(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
            this.transactionId = 'snow-req-123';
        }
        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().startsWith('callout:ServiceNow_Named_Credential/api/now/table'));
            System.assertEquals('application/json', req.getHeader('Content-Type'));
            System.assertNotEquals(null, req.getHeader('X-Correlation-Id'));
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            response.setHeader('X-Transaction-Id', transactionId);
            return response;
        }
    }

    @TestSetup
    static void setupData() {
        SN_ConfigService.setTestData(
            new List<SN_Org_Config__mdt>{ orgConfig('US_HEALTHCARE_PROD') },
            new List<SN_Request_Type__mdt>(),
            new List<SN_Routing_Rule__mdt>(),
            new List<SN_Assignment_Target__mdt>()
        );
        SN_ServiceNowClient.setEndpointConfigTestData(new List<SN_Endpoint_Config__mdt>{ endpointConfig('SNOW_US_PROD') });
    }

    @IsTest
    static void createsIncidentUsingNamedCredentialAndSafeResponseHandling() {
        Test.setMock(HttpCalloutMock.class, new MockResponder(201, '{"result":{"sys_id":"abc123"}}'));
        SN_ServiceNowClient.IncidentCreateRequest request = new SN_ServiceNowClient.IncidentCreateRequest();
        request.orgKey = 'US_HEALTHCARE_PROD';
        request.correlationId = 'corr-1';
        request.idempotencyKey = 'idem-1';
        request.payload = new Map<String, Object>{ 'short_description' => 'masked' };

        SN_ServiceNowClient.ResponseEnvelope response = SN_ServiceNowClient.createIncidentWithHandling(request);

        System.assertEquals(true, response.success);
        System.assertEquals(201, response.statusCode);
        System.assertEquals('corr-1', response.correlationId);
        System.assert(response.safeSummary.contains('statusCode=201'));
        System.assert(!response.safeSummary.contains('masked'));
    }

    @IsTest
    static void classifiesAuthAndRetryableTechnicalFailures() {
        Test.setMock(HttpCalloutMock.class, new MockResponder(401, '{"error":"unauthorized"}'));
        SN_ServiceNowClient.CommentRequest commentRequest = new SN_ServiceNowClient.CommentRequest();
        commentRequest.orgKey = 'US_HEALTHCARE_PROD';
        commentRequest.correlationId = 'corr-2';
        commentRequest.incidentSysId = 'inc-1';
        commentRequest.comment = 'safe note';

        SN_ServiceNowClient.ResponseEnvelope authResponse = SN_ServiceNowClient.addComment(commentRequest);
        System.assertEquals(SN_ServiceNowClient.FailureCategory.AUTH, authResponse.failureCategory);
        System.assertEquals(false, authResponse.retryable);

        Test.setMock(HttpCalloutMock.class, new MockResponder(503, '{"error":"down"}'));
        SN_ServiceNowClient.FileSyncRequest fileRequest = new SN_ServiceNowClient.FileSyncRequest();
        fileRequest.orgKey = 'US_HEALTHCARE_PROD';
        fileRequest.correlationId = 'corr-3';
        fileRequest.incidentSysId = 'inc-1';
        fileRequest.fileName = 'a.txt';
        fileRequest.contentType = 'text/plain';
        fileRequest.base64Body = EncodingUtil.base64Encode(Blob.valueOf('x'));

        SN_ServiceNowClient.ResponseEnvelope techResponse = SN_ServiceNowClient.synchronizeFile(fileRequest);
        System.assertEquals(SN_ServiceNowClient.FailureCategory.TECHNICAL, techResponse.failureCategory);
        System.assertEquals(true, techResponse.retryable);
    }

    @IsTest
    static void throwsConfigurationExceptionWhenEndpointMetadataIsMissing() {
        SN_ServiceNowClient.clearEndpointConfigTestData();
        try {
            SN_ServiceNowClient.send('GET', '/incident', null, 'US_HEALTHCARE_PROD');
            System.assert(false, 'Expected configuration exception.');
        } catch (SN_ServiceNowClient.ServiceNowClientException ex) {
            System.assertEquals(SN_ServiceNowClient.FailureCategory.CONFIGURATION, ex.failureCategory);
            System.assertEquals('MISSING_ENDPOINT_CONFIG', ex.errorCode);
        }
    }

    private static SN_Org_Config__mdt orgConfig(String orgKey) {
        SN_Org_Config__mdt record = new SN_Org_Config__mdt();
        record.DeveloperName = orgKey;
        record.MasterLabel = orgKey;
        record.Org_Key__c = orgKey;
        record.Is_Active__c = true;
        record.Endpoint_Config_Key__c = 'SNOW_US_PROD';
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
