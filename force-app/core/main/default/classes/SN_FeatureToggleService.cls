public with sharing class SN_FeatureToggleService {
    @TestVisible private static List<SN_Feature_Toggle__mdt> toggleOverrides;
    private static Map<String, Map<String, Map<String, FeatureToggle>>> togglesByOrgAndRequestType;

    public class FeatureToggle {
        public String developerName, orgKey, requestTypeKey, featureKey, rolloutGroup, notes, dependsOnFeatureKey;
        public Boolean isEnabled, isKillSwitch;
        public FeatureToggle(SN_Feature_Toggle__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            requestTypeKey = record.Request_Type_Key__c;
            featureKey = record.Feature_Key__c;
            rolloutGroup = record.Rollout_Group__c;
            isEnabled = record.Is_Enabled__c;
            isKillSwitch = record.Is_Kill_Switch__c;
            dependsOnFeatureKey = record.Depends_On_Feature__c;
            notes = record.Notes__c;
        }
    }

    public static Boolean isEnabled(String featureKey, String orgKey) { return isEnabled(featureKey, orgKey, null); }
    public static Boolean isEnabled(String featureKey, String orgKey, String requestTypeKey) {
        FeatureToggle toggle = getToggle(featureKey, orgKey, requestTypeKey);
        if (toggle == null || toggle.isEnabled != true) return false;
        if (isKillSwitchActive(featureKey, orgKey, requestTypeKey)) return false;
        if (!String.isBlank(toggle.dependsOnFeatureKey) && !isEnabled(toggle.dependsOnFeatureKey, orgKey, requestTypeKey, new Set<String>{ featureKey })) return false;
        return true;
    }
    public static FeatureToggle getToggle(String featureKey, String orgKey) { return getToggle(featureKey, orgKey, null); }
    public static FeatureToggle getToggle(String featureKey, String orgKey, String requestTypeKey) {
        if (String.isBlank(featureKey)) return null;
        ensureCache();
        for (String orgScope : new List<String>{ scopedKey(orgKey), scopedKey(null) }) {
            Map<String, Map<String, FeatureToggle>> byRequestType = togglesByOrgAndRequestType.get(orgScope);
            if (byRequestType == null) continue;
            for (String requestTypeScope : new List<String>{ scopedKey(requestTypeKey), scopedKey(null) }) {
                Map<String, FeatureToggle> toggles = byRequestType.get(requestTypeScope);
                if (toggles != null && toggles.containsKey(featureKey)) return toggles.get(featureKey);
            }
        }
        return null;
    }
    public static Boolean isKillSwitchActive(String featureKey, String orgKey, String requestTypeKey) {
        FeatureToggle kill = getToggle(featureKey + '_KILL_SWITCH', orgKey, requestTypeKey);
        return kill != null && kill.isKillSwitch == true && kill.isEnabled == true;
    }
    public static Map<String, FeatureToggle> getToggles(String orgKey) { return getToggles(orgKey, null); }
    public static Map<String, FeatureToggle> getToggles(String orgKey, String requestTypeKey) {
        ensureCache();
        Map<String, FeatureToggle> results = new Map<String, FeatureToggle>();
        for (String orgScope : new List<String>{ scopedKey(null), scopedKey(orgKey) }) {
            Map<String, Map<String, FeatureToggle>> byRequestType = togglesByOrgAndRequestType.get(orgScope);
            if (byRequestType == null) continue;
            for (String requestTypeScope : new List<String>{ scopedKey(null), scopedKey(requestTypeKey) }) {
                Map<String, FeatureToggle> toggles = byRequestType.get(requestTypeScope);
                if (toggles != null) results.putAll(toggles);
            }
        }
        return results;
    }

    @TestVisible static void setTestData(List<SN_Feature_Toggle__mdt> toggleRecords) { toggleOverrides = toggleRecords; togglesByOrgAndRequestType = null; }
    @TestVisible static void resetCache() { togglesByOrgAndRequestType = null; }

    private static Boolean isEnabled(String featureKey, String orgKey, String requestTypeKey, Set<String> visited) {
        if (visited.contains(featureKey)) return false;
        visited.add(featureKey);
        FeatureToggle toggle = getToggle(featureKey, orgKey, requestTypeKey);
        if (toggle == null || toggle.isEnabled != true || isKillSwitchActive(featureKey, orgKey, requestTypeKey)) return false;
        if (!String.isBlank(toggle.dependsOnFeatureKey)) return isEnabled(toggle.dependsOnFeatureKey, orgKey, requestTypeKey, visited);
        return true;
    }

    private static void ensureCache() {
        if (togglesByOrgAndRequestType != null) return;
        togglesByOrgAndRequestType = new Map<String, Map<String, Map<String, FeatureToggle>>>();
        for (SN_Feature_Toggle__mdt record : getRecords()) {
            if (String.isBlank(record.Feature_Key__c)) continue;
            String orgScope = scopedKey(record.Org_Key__c);
            String requestTypeScope = scopedKey(record.Request_Type_Key__c);
            if (!togglesByOrgAndRequestType.containsKey(orgScope)) togglesByOrgAndRequestType.put(orgScope, new Map<String, Map<String, FeatureToggle>>());
            if (!togglesByOrgAndRequestType.get(orgScope).containsKey(requestTypeScope)) togglesByOrgAndRequestType.get(orgScope).put(requestTypeScope, new Map<String, FeatureToggle>());
            togglesByOrgAndRequestType.get(orgScope).get(requestTypeScope).put(record.Feature_Key__c, new FeatureToggle(record));
        }
    }
    private static List<SN_Feature_Toggle__mdt> getRecords() {
        if (Test.isRunningTest() && toggleOverrides != null) return toggleOverrides;
        return [SELECT DeveloperName, Org_Key__c, Request_Type_Key__c, Feature_Key__c, Rollout_Group__c, Is_Enabled__c, Is_Kill_Switch__c, Depends_On_Feature__c, Notes__c FROM SN_Feature_Toggle__mdt];
    }
    private static String scopedKey(String key) { return String.isBlank(key) ? '__GLOBAL__' : key; }
}
