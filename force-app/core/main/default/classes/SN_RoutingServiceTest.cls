@IsTest
private class SN_RoutingServiceTest {
    @TestSetup
    static void setupData() {
        IntegrationTestUtils.applyBaselineMetadata();
    }

    @IsTest
    static void selectsHighPriorityRuleForOrgA() {
        SN_RoutingService.RoutingContext context = new SN_RoutingService.RoutingContext();
        context.orgKey = 'ORG_A';
        context.requestTypeKey = 'REQUEST_X';
        context.metadata.put('priority', 'high');

        SN_RoutingService.RoutingOutcome outcome = SN_RoutingService.resolve(context);

        System.assertEquals('ORG_A_TARGET', outcome.assignmentTargetKey);
        System.assertEquals('P1_OVERRIDE', outcome.priorityBehavior);
        System.assertEquals(true, outcome.syncComments);
        System.assertEquals(false, outcome.usedFallback);
    }

    @IsTest
    static void fallsBackToDefaultRuleWhenNoSpecificRuleMatches() {
        SN_RoutingService.RoutingContext context = new SN_RoutingService.RoutingContext();
        context.orgKey = 'ORG_B';
        context.requestTypeKey = 'REQUEST_Y';
        context.metadata.put('priority', 'low');

        SN_RoutingService.RoutingOutcome outcome = SN_RoutingService.resolve(context);

        System.assertEquals('ORG_B_FALLBACK', outcome.assignmentTargetKey);
        System.assertEquals('TEMPLATE_B', outcome.incidentTemplateKey);
        System.assertEquals(true, outcome.stopDownstreamProcessing);
        System.assertEquals(true, outcome.usedFallback);
    }
}
