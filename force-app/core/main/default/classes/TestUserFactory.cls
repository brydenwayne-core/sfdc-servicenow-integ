@IsTest
public with sharing class TestUserFactory {
    public static User createIntegrationUser(Boolean doInsert) {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User userRecord = new User(
            Alias = 'tusr',
            Email = 'integration+' + TestDataFactory.uniqueSuffix() + '@example.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Integration Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = profileRecord.Id,
            Username = 'integration+' + TestDataFactory.uniqueSuffix() + '@example.test'
        );
        if (doInsert) {
            insert userRecord;
        }
        return userRecord;
    }
}
