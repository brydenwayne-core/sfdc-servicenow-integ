@IsTest
private class SN_IncidentLinkServiceTest {
    @IsTest
    static void upsertLinkCreatesAndUpdatesNormalizedRecord() {
        Integration_Transaction__c transactionRecord = new Integration_Transaction__c(
            CorrelationId__c = 'corr-1',
            IdempotencyKey__c = 'idem-1',
            SourceSystem__c = 'Salesforce',
            Operation__c = 'createIncident',
            SourceRecordId__c = '500000000000001',
            RequestType__c = 'REQ_STANDARD',
            SalesforceOrgCode__c = 'US_HEALTHCARE_PROD',
            Status__c = 'In Progress',
            StartedAt__c = System.now(),
            RetryCount__c = 0
        );
        insert transactionRecord;

        SN_IncidentLinkService.LinkContext context = new SN_IncidentLinkService.LinkContext();
        context.transactionId = transactionRecord.Id;
        context.sourceRecordId = '500000000000001';
        context.sourceObjectApiName = 'Case';
        context.sourceRecordLabel = '00001001';
        context.sourceRecordType = 'Clinical';
        context.orgCode = 'US_HEALTHCARE_PROD';
        context.businessUnit = 'Healthcare East';
        context.serviceNowIncidentId = 'sys-1';
        context.serviceNowIncidentNumber = 'INC0010001';
        context.linkStatus = 'Active';
        context.lastSyncAt = System.now();

        Test.startTest();
        SN_IncidentLinkService.upsertLink(context);
        context.serviceNowIncidentNumber = 'INC0010002';
        SN_IncidentLinkService.upsertLink(context);
        Test.stopTest();

        List<ServiceNow_Incident_Link__c> links = [
            SELECT Integration_Transaction__c, Salesforce_Record_Id__c, Source_Object_API_Name__c,
                Source_Record_Label__c, Source_Record_Type__c, Salesforce_Org_Code__c,
                Business_Unit__c, ServiceNow_Incident_Id__c, ServiceNow_Incident_Number__c,
                Link_Status__c
            FROM ServiceNow_Incident_Link__c
            WHERE Integration_Transaction__c = :transactionRecord.Id
        ];
        System.assertEquals(1, links.size());
        System.assertEquals('INC0010002', links[0].ServiceNow_Incident_Number__c);
        System.assertEquals('Healthcare East', links[0].Business_Unit__c);
        System.assertEquals('Case', links[0].Source_Object_API_Name__c);
    }
}
