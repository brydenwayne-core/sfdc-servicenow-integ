public with sharing class SN_ConfigService {
    @TestVisible
    private static List<SN_Org_Config__mdt> orgConfigOverrides;
    @TestVisible
    private static List<SN_Request_Type__mdt> requestTypeOverrides;
    @TestVisible
    private static List<SN_Routing_Rule__mdt> routingRuleOverrides;
    @TestVisible
    private static List<SN_Assignment_Target__mdt> assignmentTargetOverrides;

    private static Map<String, OrgConfig> orgConfigCache;
    private static Map<String, Map<String, RequestTypeConfig>> requestTypeCacheByOrg;
    private static Map<String, Map<String, AssignmentTargetConfig>> assignmentTargetCacheByOrg;
    private static Map<String, Map<String, List<RoutingRuleConfig>>> routingRulesCacheByOrgAndRequestType;

    public class OrgConfig {
        public String developerName;
        public String orgKey;
        public String salesforceOrgId;
        public String businessUnit;
        public String environment;
        public Boolean isActive;
        public String defaultRequestTypeKey;
        public String endpointConfigKey;

        public OrgConfig(SN_Org_Config__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            salesforceOrgId = record.Salesforce_Org_Id__c;
            businessUnit = record.Business_Unit__c;
            environment = record.Environment__c;
            isActive = record.Is_Active__c;
            defaultRequestTypeKey = record.Default_Request_Type__c;
            endpointConfigKey = record.Endpoint_Config_Key__c;
        }
    }

    public class RequestTypeConfig {
        public String developerName;
        public String orgKey;
        public String requestTypeKey;
        public String sourceObject;
        public String operationMode;
        public String incidentTemplateKey;
        public String routingKey;
        public Boolean isActive;

        public RequestTypeConfig(SN_Request_Type__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            requestTypeKey = record.Request_Type_Key__c;
            sourceObject = record.Source_Object__c;
            operationMode = record.Operation_Mode__c;
            incidentTemplateKey = record.Incident_Template_Key__c;
            routingKey = record.Routing_Key__c;
            isActive = record.Is_Active__c;
        }
    }

    public class RoutingRuleConfig {
        public String developerName;
        public String orgKey;
        public String requestTypeKey;
        public String matchCriteria;
        public String assignmentTargetKey;
        public Integer priority;
        public Boolean isActive;
        public Boolean isDefault;

        public RoutingRuleConfig(SN_Routing_Rule__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            requestTypeKey = record.Request_Type_Key__c;
            matchCriteria = record.Match_Criteria__c;
            assignmentTargetKey = record.Assignment_Target_Key__c;
            priority = record.Priority__c == null ? null : Integer.valueOf(record.Priority__c);
            isActive = record.Is_Active__c;
            isDefault = record.Is_Default__c;
        }
    }

    public class AssignmentTargetConfig {
        public String developerName;
        public String orgKey;
        public String assignmentTargetKey;
        public String assignmentType;
        public String externalAssignmentId;
        public String displayName;
        public Boolean isActive;

        public AssignmentTargetConfig(SN_Assignment_Target__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            assignmentTargetKey = record.Assignment_Target_Key__c;
            assignmentType = record.Assignment_Type__c;
            externalAssignmentId = record.External_Assignment_Id__c;
            displayName = record.Display_Name__c;
            isActive = record.Is_Active__c;
        }
    }

    public class ConfigBundle {
        public OrgConfig orgConfig;
        public RequestTypeConfig requestTypeConfig;
        public List<RoutingRuleConfig> routingRules;
        public Map<String, AssignmentTargetConfig> assignmentTargetsByKey;

        public ConfigBundle(OrgConfig orgConfig, RequestTypeConfig requestTypeConfig,
            List<RoutingRuleConfig> routingRules, Map<String, AssignmentTargetConfig> assignmentTargetsByKey) {
            this.orgConfig = orgConfig;
            this.requestTypeConfig = requestTypeConfig;
            this.routingRules = routingRules;
            this.assignmentTargetsByKey = assignmentTargetsByKey;
        }
    }

    /** Resolves org-level configuration needed for the current integration transaction. */
    public static SN_Org_Config__mdt getOrgConfig(String orgKey) {
        OrgConfig config = getOrgConfigWrapper(orgKey);
        if (config == null) {
            return null;
        }
        return findOrgConfigRecord(orgKey);
    }

    public static OrgConfig getOrgConfigWrapper(String orgKey) {
        if (String.isBlank(orgKey)) {
            return null;
        }
        ensureOrgCache();
        return orgConfigCache.get(orgKey);
    }

    /** Resolves request-type configuration and field mapping metadata. */
    public static SN_Request_Type__mdt getRequestTypeConfig(String orgKey, String requestTypeKey) {
        RequestTypeConfig config = getRequestTypeConfigWrapper(orgKey, requestTypeKey);
        if (config == null) {
            return null;
        }
        return findRequestTypeRecord(orgKey, config.requestTypeKey);
    }

    public static RequestTypeConfig getRequestTypeConfigWrapper(String orgKey, String requestTypeKey) {
        if (String.isBlank(requestTypeKey)) {
            OrgConfig orgConfig = getOrgConfigWrapper(orgKey);
            requestTypeKey = orgConfig == null ? null : orgConfig.defaultRequestTypeKey;
        }
        if (String.isBlank(requestTypeKey)) {
            return null;
        }
        ensureRequestTypeCache();
        return getScopedValue(requestTypeCacheByOrg, orgKey, requestTypeKey);
    }

    public static List<RoutingRuleConfig> getRoutingRules(String orgKey, String requestTypeKey) {
        ensureRoutingRulesCache();
        String effectiveRequestTypeKey = requestTypeKey;
        if (String.isBlank(effectiveRequestTypeKey)) {
            RequestTypeConfig requestType = getRequestTypeConfigWrapper(orgKey, null);
            effectiveRequestTypeKey = requestType == null ? null : requestType.requestTypeKey;
        }
        if (String.isBlank(effectiveRequestTypeKey)) {
            return new List<RoutingRuleConfig>();
        }

        List<RoutingRuleConfig> rules = new List<RoutingRuleConfig>();
        rules.addAll(getScopedRoutingRules(orgKey, effectiveRequestTypeKey));
        return rules;
    }

    public static AssignmentTargetConfig getAssignmentTarget(String orgKey, String assignmentTargetKey) {
        if (String.isBlank(assignmentTargetKey)) {
            return null;
        }
        ensureAssignmentTargetCache();
        return getScopedValue(assignmentTargetCacheByOrg, orgKey, assignmentTargetKey);
    }

    public static ConfigBundle getBundle(String orgKey, String requestTypeKey) {
        OrgConfig orgConfig = getOrgConfigWrapper(orgKey);
        RequestTypeConfig requestTypeConfig = getRequestTypeConfigWrapper(orgKey, requestTypeKey);
        List<RoutingRuleConfig> routingRules = getRoutingRules(orgKey, requestTypeConfig == null ? requestTypeKey : requestTypeConfig.requestTypeKey);
        Map<String, AssignmentTargetConfig> targetsByKey = new Map<String, AssignmentTargetConfig>();
        for (RoutingRuleConfig rule : routingRules) {
            AssignmentTargetConfig target = getAssignmentTarget(orgKey, rule.assignmentTargetKey);
            if (target != null) {
                targetsByKey.put(target.assignmentTargetKey, target);
            }
        }
        return new ConfigBundle(orgConfig, requestTypeConfig, routingRules, targetsByKey);
    }

    @TestVisible
    static void setTestData(List<SN_Org_Config__mdt> orgConfigs, List<SN_Request_Type__mdt> requestTypes,
        List<SN_Routing_Rule__mdt> routingRules, List<SN_Assignment_Target__mdt> assignmentTargets) {
        orgConfigOverrides = orgConfigs;
        requestTypeOverrides = requestTypes;
        routingRuleOverrides = routingRules;
        assignmentTargetOverrides = assignmentTargets;
        resetCaches();
    }

    @TestVisible
    static void resetCaches() {
        orgConfigCache = null;
        requestTypeCacheByOrg = null;
        assignmentTargetCacheByOrg = null;
        routingRulesCacheByOrgAndRequestType = null;
    }

    private static void ensureOrgCache() {
        if (orgConfigCache != null) {
            return;
        }
        orgConfigCache = new Map<String, OrgConfig>();
        for (SN_Org_Config__mdt record : getOrgConfigRecords()) {
            if (record.Is_Active__c == true && !String.isBlank(record.Org_Key__c)) {
                orgConfigCache.put(record.Org_Key__c, new OrgConfig(record));
            }
        }
    }

    private static void ensureRequestTypeCache() {
        if (requestTypeCacheByOrg != null) {
            return;
        }
        requestTypeCacheByOrg = new Map<String, Map<String, RequestTypeConfig>>();
        for (SN_Request_Type__mdt record : getRequestTypeRecords()) {
            if (record.Is_Active__c == true && !String.isBlank(record.Request_Type_Key__c)) {
                putScopedRequestType(requestTypeCacheByOrg, record.Org_Key__c, record.Request_Type_Key__c, new RequestTypeConfig(record));
            }
        }
    }

    private static void ensureAssignmentTargetCache() {
        if (assignmentTargetCacheByOrg != null) {
            return;
        }
        assignmentTargetCacheByOrg = new Map<String, Map<String, AssignmentTargetConfig>>();
        for (SN_Assignment_Target__mdt record : getAssignmentTargetRecords()) {
            if (record.Is_Active__c == true && !String.isBlank(record.Assignment_Target_Key__c)) {
                putScopedAssignmentTarget(assignmentTargetCacheByOrg, record.Org_Key__c, record.Assignment_Target_Key__c, new AssignmentTargetConfig(record));
            }
        }
    }

    private static void ensureRoutingRulesCache() {
        if (routingRulesCacheByOrgAndRequestType != null) {
            return;
        }
        routingRulesCacheByOrgAndRequestType = new Map<String, Map<String, List<RoutingRuleConfig>>>();
        for (SN_Routing_Rule__mdt record : getRoutingRuleRecords()) {
            if (record.Is_Active__c == true && !String.isBlank(record.Request_Type_Key__c)) {
                String orgScope = scopedKey(record.Org_Key__c);
                if (!routingRulesCacheByOrgAndRequestType.containsKey(orgScope)) {
                    routingRulesCacheByOrgAndRequestType.put(orgScope, new Map<String, List<RoutingRuleConfig>>());
                }
                Map<String, List<RoutingRuleConfig>> rulesByRequestType = routingRulesCacheByOrgAndRequestType.get(orgScope);
                if (!rulesByRequestType.containsKey(record.Request_Type_Key__c)) {
                    rulesByRequestType.put(record.Request_Type_Key__c, new List<RoutingRuleConfig>());
                }
                rulesByRequestType.get(record.Request_Type_Key__c).add(new RoutingRuleConfig(record));
            }
        }

        for (Map<String, List<RoutingRuleConfig>> scopedRules : routingRulesCacheByOrgAndRequestType.values()) {
            for (String requestTypeKey : scopedRules.keySet()) {
                scopedRules.get(requestTypeKey).sort(new RoutingRuleComparator());
            }
        }
    }

    private class RoutingRuleComparator implements System.Comparator<RoutingRuleConfig> {
        public Integer compare(RoutingRuleConfig a, RoutingRuleConfig b) {
            Integer left = a.priority == null ? Integer.MAX_VALUE : a.priority;
            Integer right = b.priority == null ? Integer.MAX_VALUE : b.priority;
            if (left == right) {
                return String.valueOf(a.developerName).compareToIgnoreCase(String.valueOf(b.developerName));
            }
            return left < right ? -1 : 1;
        }
    }

    private static List<RoutingRuleConfig> getScopedRoutingRules(String orgKey, String requestTypeKey) {
        List<RoutingRuleConfig> results = new List<RoutingRuleConfig>();
        for (String scope : new List<String>{ scopedKey(orgKey), scopedKey(null) }) {
            Map<String, List<RoutingRuleConfig>> rulesByRequestType = routingRulesCacheByOrgAndRequestType.get(scope);
            if (rulesByRequestType != null && rulesByRequestType.containsKey(requestTypeKey)) {
                results.addAll(rulesByRequestType.get(requestTypeKey));
            }
        }
        return results;
    }

    private static void putScopedRequestType(Map<String, Map<String, RequestTypeConfig>> cache, String orgKey, String key, RequestTypeConfig value) {
        String scope = scopedKey(orgKey);
        if (!cache.containsKey(scope)) {
            cache.put(scope, new Map<String, RequestTypeConfig>());
        }
        cache.get(scope).put(key, value);
    }

    private static void putScopedAssignmentTarget(Map<String, Map<String, AssignmentTargetConfig>> cache, String orgKey, String key, AssignmentTargetConfig value) {
        String scope = scopedKey(orgKey);
        if (!cache.containsKey(scope)) {
            cache.put(scope, new Map<String, AssignmentTargetConfig>());
        }
        cache.get(scope).put(key, value);
    }

    private static String scopedKey(String orgKey) {
        return String.isBlank(orgKey) ? '__GLOBAL__' : orgKey;
    }

    private static List<SN_Org_Config__mdt> getOrgConfigRecords() {
        if (Test.isRunningTest() && orgConfigOverrides != null) {
            return orgConfigOverrides;
        }
        return [
            SELECT DeveloperName, Org_Key__c, Salesforce_Org_Id__c, Business_Unit__c, Environment__c,
                Is_Active__c, Default_Request_Type__c, Endpoint_Config_Key__c
            FROM SN_Org_Config__mdt
        ];
    }

    private static List<SN_Request_Type__mdt> getRequestTypeRecords() {
        if (Test.isRunningTest() && requestTypeOverrides != null) {
            return requestTypeOverrides;
        }
        return [
            SELECT DeveloperName, Org_Key__c, Request_Type_Key__c, Source_Object__c, Operation_Mode__c,
                Incident_Template_Key__c, Routing_Key__c, Is_Active__c
            FROM SN_Request_Type__mdt
        ];
    }

    private static List<SN_Routing_Rule__mdt> getRoutingRuleRecords() {
        if (Test.isRunningTest() && routingRuleOverrides != null) {
            return routingRuleOverrides;
        }
        return [
            SELECT DeveloperName, Org_Key__c, Request_Type_Key__c, Match_Criteria__c, Assignment_Target_Key__c,
                Priority__c, Is_Active__c, Is_Default__c
            FROM SN_Routing_Rule__mdt
        ];
    }

    private static List<SN_Assignment_Target__mdt> getAssignmentTargetRecords() {
        if (Test.isRunningTest() && assignmentTargetOverrides != null) {
            return assignmentTargetOverrides;
        }
        return [
            SELECT DeveloperName, Org_Key__c, Assignment_Target_Key__c, Assignment_Type__c,
                External_Assignment_Id__c, Display_Name__c, Is_Active__c
            FROM SN_Assignment_Target__mdt
        ];
    }

    private static SN_Org_Config__mdt findOrgConfigRecord(String orgKey) {
        for (SN_Org_Config__mdt record : getOrgConfigRecords()) {
            if (record.Org_Key__c == orgKey && record.Is_Active__c == true) {
                return record;
            }
        }
        return null;
    }

    private static SN_Request_Type__mdt findRequestTypeRecord(String orgKey, String requestTypeKey) {
        for (SN_Request_Type__mdt record : getRequestTypeRecords()) {
            if (record.Request_Type_Key__c == requestTypeKey && record.Is_Active__c == true &&
                (record.Org_Key__c == orgKey || String.isBlank(record.Org_Key__c))) {
                return record;
            }
        }
        return null;
    }
}
