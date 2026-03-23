@IsTest
private class SN_FeatureToggleServiceTest {
    @IsTest
    static void supportsOrgRequestTypeAndKillSwitchControls() {
        List<SN_Feature_Toggle__mdt> toggles = new List<SN_Feature_Toggle__mdt>{
            TestDataFactory.featureToggle(null, 'CASE_TO_INCIDENT_SYNC', true),
            TestDataFactory.featureToggle('ORG_A', 'CASE_TO_INCIDENT_SYNC', true),
            TestDataFactory.featureToggle('ORG_A', 'COMMENT_SYNC', true),
            TestDataFactory.featureToggle('ORG_A', 'FILE_SYNC', true)
        };
        toggles[2].Request_Type_Key__c = 'REQUEST_X';
        toggles[3].Depends_On_Feature__c = 'CASE_TO_INCIDENT_SYNC';
        SN_Feature_Toggle__mdt killSwitch = TestDataFactory.featureToggle('ORG_A', 'COMMENT_SYNC_KILL_SWITCH', true);
        killSwitch.Request_Type_Key__c = 'REQUEST_Y';
        killSwitch.Is_Kill_Switch__c = true;
        toggles.add(killSwitch);
        SN_FeatureToggleService.setTestData(toggles);

        System.assertEquals(true, SN_FeatureToggleService.isEnabled('CASE_TO_INCIDENT_SYNC', 'ORG_A', 'REQUEST_X'));
        System.assertEquals(true, SN_FeatureToggleService.isEnabled('FILE_SYNC', 'ORG_A', 'REQUEST_X'));
        System.assertEquals(true, SN_FeatureToggleService.isEnabled('COMMENT_SYNC', 'ORG_A', 'REQUEST_X'));
        System.assertEquals(false, SN_FeatureToggleService.isEnabled('COMMENT_SYNC', 'ORG_A', 'REQUEST_Y'));
        System.assertEquals(true, SN_FeatureToggleService.isEnabled('CASE_TO_INCIDENT_SYNC', 'UNLISTED_ORG', 'ANY'));
    }
}
