@IsTest
private class SN_IdempotencyServiceTest {
    @IsTest
    static void createsAndReusesTransactionsViaFactory() {
        Integration_Transaction__c existing = TestIntegrationFactory.createTransaction('Succeeded');

        Id foundId = SN_IdempotencyService.findExistingTransaction(existing.IdempotencyKey__c);
        SN_IdempotencyService.ReservationResult reservation = SN_IdempotencyService.reserveTransaction(
            existing.IdempotencyKey__c,
            'corr-new',
            'US_HEALTHCARE_PROD',
            'INCIDENT_STANDARD',
            Id.valueOf(existing.SourceRecordId__c)
        );

        System.assertEquals(existing.Id, foundId);
        System.assertEquals(false, reservation.shouldProcess);
        System.assertEquals(true, reservation.existingSuccess);
    }

    @IsTest
    static void reopensFailedTransactionForRetry() {
        Integration_Transaction__c failedRecord = TestIntegrationFactory.createTransaction('Failed');

        SN_IdempotencyService.ReservationResult reservation = SN_IdempotencyService.reserveTransaction(
            failedRecord.IdempotencyKey__c,
            'corr-retry',
            'US_HEALTHCARE_PROD',
            'INCIDENT_STANDARD',
            Id.valueOf(failedRecord.SourceRecordId__c)
        );

        Integration_Transaction__c refreshed = [SELECT Status__c, RetryCount__c FROM Integration_Transaction__c WHERE Id = :failedRecord.Id];
        System.assertEquals(true, reservation.shouldProcess);
        System.assertEquals(true, reservation.retryExecution);
        System.assertEquals('Retrying', refreshed.Status__c);
        System.assertEquals(1, refreshed.RetryCount__c);
    }
}
