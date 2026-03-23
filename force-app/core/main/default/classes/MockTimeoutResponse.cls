@IsTest
public with sharing class MockTimeoutResponse implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        throw new CalloutException('Read timed out');
    }
}
