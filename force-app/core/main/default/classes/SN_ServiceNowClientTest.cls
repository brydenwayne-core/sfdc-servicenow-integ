@IsTest
private class SN_ServiceNowClientTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void handlesCreateAndUpdateSuccessThroughReusableMocks() {
        Test.setMock(HttpCalloutMock.class, MockServiceNowHttpResponse.createIncidentSuccess());
        SN_ServiceNowClient.IncidentCreateRequest createRequest = new SN_ServiceNowClient.IncidentCreateRequest();
        createRequest.orgKey = 'US_HEALTHCARE_PROD';
        createRequest.correlationId = 'corr-create';
        createRequest.idempotencyKey = 'idem-create';
        createRequest.payload = new Map<String, Object>{ 'short_description' => 'masked' };

        SN_ServiceNowClient.ResponseEnvelope createResponse = SN_ServiceNowClient.createIncidentWithHandling(createRequest);

        System.assertEquals(true, createResponse.success);
        System.assertEquals(201, createResponse.statusCode);
        System.assert(createResponse.safeSummary.contains('statusCode=201'));
        System.assert(!createResponse.safeSummary.contains('masked'));

        Test.setMock(HttpCalloutMock.class, MockServiceNowHttpResponse.updateIncidentSuccess());
        SN_ServiceNowClient.IncidentUpdateRequest updateRequest = new SN_ServiceNowClient.IncidentUpdateRequest();
        updateRequest.orgKey = 'US_HEALTHCARE_PROD';
        updateRequest.correlationId = 'corr-update';
        updateRequest.idempotencyKey = 'idem-update';
        updateRequest.incidentSysId = 'inc-1001';
        updateRequest.payload = new Map<String, Object>{ 'comments' => 'safe note' };

        SN_ServiceNowClient.ResponseEnvelope updateResponse = SN_ServiceNowClient.updateIncident(updateRequest);
        System.assertEquals(true, updateResponse.success);
        System.assertEquals(200, updateResponse.statusCode);
    }

    @IsTest
    static void classifiesAuthValidationAndTimeoutFailures() {
        Test.setMock(HttpCalloutMock.class, MockServiceNowErrorResponse.authenticationFailure());
        SN_ServiceNowClient.CommentRequest commentRequest = new SN_ServiceNowClient.CommentRequest();
        commentRequest.orgKey = 'US_HEALTHCARE_PROD';
        commentRequest.correlationId = 'corr-auth';
        commentRequest.incidentSysId = 'inc-1';
        commentRequest.comment = 'safe note';
        SN_ServiceNowClient.ResponseEnvelope authResponse = SN_ServiceNowClient.addComment(commentRequest);
        System.assertEquals(SN_ServiceNowClient.FailureCategory.AUTH, authResponse.failureCategory);

        Test.setMock(HttpCalloutMock.class, MockServiceNowErrorResponse.validationFailure());
        SN_ServiceNowClient.IncidentCreateRequest invalidRequest = new SN_ServiceNowClient.IncidentCreateRequest();
        invalidRequest.orgKey = 'US_HEALTHCARE_PROD';
        invalidRequest.correlationId = 'corr-validation';
        invalidRequest.payload = new Map<String, Object>{ 'invalid' => true };
        SN_ServiceNowClient.ResponseEnvelope validationResponse = SN_ServiceNowClient.createIncidentWithHandling(invalidRequest);
        System.assertEquals(SN_ServiceNowClient.FailureCategory.FUNCTIONAL, validationResponse.failureCategory);
        System.assertEquals(false, validationResponse.retryable);

        Test.setMock(HttpCalloutMock.class, new MockTimeoutResponse());
        try {
            SN_ServiceNowClient.send('GET', '/incident', null, 'US_HEALTHCARE_PROD');
            System.assert(false, 'Expected timeout exception');
        } catch (SN_ServiceNowClient.ServiceNowClientException ex) {
            System.assertEquals(SN_ServiceNowClient.FailureCategory.TECHNICAL, ex.failureCategory);
            System.assertEquals(true, ex.retryable);
        }
    }
}
