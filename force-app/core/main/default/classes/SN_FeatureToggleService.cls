public with sharing class SN_FeatureToggleService {
    @TestVisible
    private static List<SN_Feature_Toggle__mdt> toggleOverrides;
    private static Map<String, Map<String, FeatureToggle>> togglesByOrg;

    public class FeatureToggle {
        public String developerName;
        public String orgKey;
        public String featureKey;
        public String rolloutGroup;
        public Boolean isEnabled;
        public String notes;

        public FeatureToggle(SN_Feature_Toggle__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            featureKey = record.Feature_Key__c;
            rolloutGroup = record.Rollout_Group__c;
            isEnabled = record.Is_Enabled__c;
            notes = record.Notes__c;
        }
    }

    /** Evaluates whether a named feature is enabled for the supplied org context. */
    public static Boolean isEnabled(String featureKey, String orgKey) {
        FeatureToggle toggle = getToggle(featureKey, orgKey);
        return toggle != null && toggle.isEnabled == true;
    }

    public static FeatureToggle getToggle(String featureKey, String orgKey) {
        if (String.isBlank(featureKey)) {
            return null;
        }
        ensureCache();
        for (String scope : new List<String>{ scopedKey(orgKey), scopedKey(null) }) {
            if (togglesByOrg.containsKey(scope) && togglesByOrg.get(scope).containsKey(featureKey)) {
                return togglesByOrg.get(scope).get(featureKey);
            }
        }
        return null;
    }

    public static Map<String, FeatureToggle> getToggles(String orgKey) {
        ensureCache();
        Map<String, FeatureToggle> results = new Map<String, FeatureToggle>();
        if (togglesByOrg.containsKey(scopedKey(null))) {
            results.putAll(togglesByOrg.get(scopedKey(null)));
        }
        if (togglesByOrg.containsKey(scopedKey(orgKey))) {
            results.putAll(togglesByOrg.get(scopedKey(orgKey)));
        }
        return results;
    }

    @TestVisible
    static void setTestData(List<SN_Feature_Toggle__mdt> toggleRecords) {
        toggleOverrides = toggleRecords;
        togglesByOrg = null;
    }

    @TestVisible
    static void resetCache() {
        togglesByOrg = null;
    }

    private static void ensureCache() {
        if (togglesByOrg != null) {
            return;
        }
        togglesByOrg = new Map<String, Map<String, FeatureToggle>>();
        for (SN_Feature_Toggle__mdt record : getRecords()) {
            if (String.isBlank(record.Feature_Key__c)) {
                continue;
            }
            String scope = scopedKey(record.Org_Key__c);
            if (!togglesByOrg.containsKey(scope)) {
                togglesByOrg.put(scope, new Map<String, FeatureToggle>());
            }
            togglesByOrg.get(scope).put(record.Feature_Key__c, new FeatureToggle(record));
        }
    }

    private static List<SN_Feature_Toggle__mdt> getRecords() {
        if (Test.isRunningTest() && toggleOverrides != null) {
            return toggleOverrides;
        }
        return [
            SELECT DeveloperName, Org_Key__c, Feature_Key__c, Rollout_Group__c, Is_Enabled__c, Notes__c
            FROM SN_Feature_Toggle__mdt
        ];
    }

    private static String scopedKey(String orgKey) {
        return String.isBlank(orgKey) ? '__GLOBAL__' : orgKey;
    }
}
