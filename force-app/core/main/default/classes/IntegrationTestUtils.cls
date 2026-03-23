@IsTest
public with sharing class IntegrationTestUtils {
    public static void applyBaselineMetadata() {
        new MockConfigProvider().apply();
    }

    public static SN_IntegrationOrchestrator.RequestContext requestContext(String orgKey, String requestTypeKey, String businessContext) {
        SN_IntegrationOrchestrator.RequestContext context = new SN_IntegrationOrchestrator.RequestContext();
        context.orgKey = orgKey;
        context.requestTypeKey = requestTypeKey;
        context.businessContext = businessContext;
        return context;
    }

    public static void configureOrchestrator(SN_IntegrationOrchestrator.IServiceNowGateway serviceNowGateway) {
        SN_IntegrationOrchestrator.resetDependencies();
        applyBaselineMetadata();
        SN_IntegrationOrchestrator.configurationGateway = new MockConfigProvider();
        SN_IntegrationOrchestrator.serviceNowGateway = serviceNowGateway;
    }

    public static void assertHealthcareSafeLogging(Integration_Transaction__c transactionRecord) {
        System.assertEquals(false, transactionRecord.Safe_Request_Summary__c != null && transactionRecord.Safe_Request_Summary__c.contains('{'));
        System.assertEquals(false, transactionRecord.Safe_Response_Summary__c != null && transactionRecord.Safe_Response_Summary__c.contains('short_description'));
        System.assertEquals(false, transactionRecord.Safe_Response_Summary__c != null && transactionRecord.Safe_Response_Summary__c.contains('description'));
    }
}
