@IsTest
public with sharing class TestScenarioFactory {
    public class Scenario {
        public String orgKey;
        public String requestTypeKey;
        public Case caseRecord;
        public String businessContext;
        public String featureKey;
    }

    public static Scenario createOrgAHighPriorityRequestTypeX() {
        Scenario scenario = new Scenario();
        scenario.orgKey = 'ORG_A';
        scenario.requestTypeKey = 'REQUEST_X';
        scenario.featureKey = 'CASE_TO_INCIDENT_SYNC';
        scenario.businessContext = 'Org A + Request Type X + Priority High';
        scenario.caseRecord = TestCaseFactory.createCaseForOrg('ORG_A', 'REQUEST_X', new Map<String, Object>{
            'Priority' => 'High',
            'Origin' => 'Phone',
            'Subject' => 'Escalated intake for Org A'
        }, true);
        return scenario;
    }

    public static Scenario createOrgBMissingRoutingRule() {
        Scenario scenario = new Scenario();
        scenario.orgKey = 'ORG_B';
        scenario.requestTypeKey = 'REQUEST_Y';
        scenario.featureKey = 'CASE_TO_INCIDENT_SYNC';
        scenario.businessContext = 'Org B + Request Type Y + missing routing rule';
        scenario.caseRecord = TestCaseFactory.createCaseForOrg('ORG_B', 'REQUEST_Y', new Map<String, Object>{
            'Priority' => 'Low',
            'Origin' => 'Email'
        }, true);
        return scenario;
    }

    public static Scenario createDuplicateIdempotentSubmission() {
        Scenario scenario = new Scenario();
        scenario.orgKey = 'US_HEALTHCARE_PROD';
        scenario.requestTypeKey = 'INCIDENT_STANDARD';
        scenario.featureKey = 'CASE_TO_INCIDENT_SYNC';
        scenario.businessContext = 'duplicate idempotent submission';
        scenario.caseRecord = TestCaseFactory.createHighPriorityIncidentCase();
        return scenario;
    }

    public static Scenario createInactiveFeatureToggleScenario() {
        Scenario scenario = new Scenario();
        scenario.orgKey = 'ORG_B';
        scenario.requestTypeKey = 'REQUEST_Y';
        scenario.featureKey = 'COMMENT_SYNC';
        scenario.businessContext = 'inactive feature toggle';
        scenario.caseRecord = TestCaseFactory.createCaseForOrg('ORG_B', 'REQUEST_Y');
        return scenario;
    }

    public static Scenario createCommentSyncScenario(Boolean enabled) {
        Scenario scenario = new Scenario();
        scenario.orgKey = enabled ? 'ORG_A' : 'ORG_B';
        scenario.requestTypeKey = enabled ? 'REQUEST_X' : 'REQUEST_Y';
        scenario.featureKey = 'COMMENT_SYNC';
        scenario.businessContext = enabled ? 'comment sync enabled' : 'comment sync disabled';
        scenario.caseRecord = TestCaseFactory.createCaseForOrg(scenario.orgKey, scenario.requestTypeKey);
        return scenario;
    }
}
