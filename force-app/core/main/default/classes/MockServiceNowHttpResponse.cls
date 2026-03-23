@IsTest
public with sharing class MockServiceNowHttpResponse implements HttpCalloutMock, SN_IntegrationOrchestrator.IServiceNowGateway {
    private Integer statusCode;
    private String body;
    private String transactionId;

    public MockServiceNowHttpResponse() {
        this(201, '{"result":{"sys_id":"inc-1001","number":"INC0010001"}}', 'snow-tx-001');
    }

    public MockServiceNowHttpResponse(Integer statusCode, String body, String transactionId) {
        this.statusCode = statusCode;
        this.body = body;
        this.transactionId = transactionId;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
        response.setHeader('X-Transaction-Id', transactionId);
        return response;
    }

    public SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request) {
        SN_ServiceNowClient.ResponseEnvelope response = new SN_ServiceNowClient.ResponseEnvelope();
        response.statusCode = statusCode;
        response.responseBody = body;
        response.correlationId = request.correlationId;
        response.requestId = transactionId;
        response.safeSummary = 'operation=createIncident;statusCode=' + statusCode + ';correlationId=' + request.correlationId;
        response.success = statusCode >= 200 && statusCode < 300;
        response.retryable = statusCode == 429 || statusCode >= 500;
        if (!response.success) {
            response.failureCategory = statusCode == 401 ? SN_ServiceNowClient.FailureCategory.AUTH :
                (response.retryable ? SN_ServiceNowClient.FailureCategory.TECHNICAL : SN_ServiceNowClient.FailureCategory.FUNCTIONAL);
            response.failureCode = response.retryable ? 'RETRYABLE_HTTP_FAILURE' : 'FUNCTIONAL_FAILURE';
        }
        return response;
    }

    public static MockServiceNowHttpResponse createIncidentSuccess() {
        return new MockServiceNowHttpResponse(201, '{"result":{"sys_id":"inc-1001","number":"INC0010001"}}', 'snow-create-1');
    }

    public static MockServiceNowHttpResponse updateIncidentSuccess() {
        return new MockServiceNowHttpResponse(200, '{"result":{"sys_id":"inc-1001","number":"INC0010001"}}', 'snow-update-1');
    }

    public static MockServiceNowHttpResponse fileSyncSuccess() {
        return new MockServiceNowHttpResponse(201, '{"result":{"sys_id":"att-1001"}}', 'snow-file-1');
    }

    public static MockServiceNowHttpResponse malformedResponse() {
        return new MockServiceNowHttpResponse(200, '{"result":', 'snow-malformed-1');
    }
}
