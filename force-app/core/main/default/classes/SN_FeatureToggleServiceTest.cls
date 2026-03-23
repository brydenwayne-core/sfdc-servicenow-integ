@IsTest
private class SN_FeatureToggleServiceTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void supportsOrgSpecificAndGlobalToggles() {
        System.assertEquals(true, SN_FeatureToggleService.isEnabled('CASE_TO_INCIDENT_SYNC', 'ORG_A'));
        System.assertEquals(false, SN_FeatureToggleService.isEnabled('COMMENT_SYNC', 'ORG_B'));
        System.assertEquals(true, SN_FeatureToggleService.isEnabled('CASE_TO_INCIDENT_SYNC', 'UNLISTED_ORG'));
    }
}
