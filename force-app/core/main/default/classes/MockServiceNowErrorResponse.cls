@IsTest
public with sharing class MockServiceNowErrorResponse extends MockServiceNowHttpResponse {
    public MockServiceNowErrorResponse(Integer statusCode, String body) {
        super(statusCode, body, 'snow-error-1');
    }

    public static MockServiceNowErrorResponse authenticationFailure() {
        return new MockServiceNowErrorResponse(401, '{"error":"unauthorized"}');
    }

    public static MockServiceNowErrorResponse validationFailure() {
        return new MockServiceNowErrorResponse(422, '{"error":"invalid payload"}');
    }

    public static MockServiceNowErrorResponse fileSyncFailure() {
        return new MockServiceNowErrorResponse(503, '{"error":"attachment service unavailable"}');
    }
}
