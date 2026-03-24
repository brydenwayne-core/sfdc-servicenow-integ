public with sharing class SN_ConfigService {
    @TestVisible @TestVisible private static List<SN_Org_Config__mdt> orgConfigOverrides;
    @TestVisible private static List<SN_Request_Type__mdt> requestTypeOverrides;
    @TestVisible private static List<SN_Routing_Rule__mdt> routingRuleOverrides;
    @TestVisible private static List<SN_Assignment_Target__mdt> assignmentTargetOverrides;
    @TestVisible private static List<SN_Incident_Template__mdt> incidentTemplateOverrides;
    @TestVisible private static List<SN_Endpoint_Config__mdt> endpointConfigOverrides;

    private static Map<String, OrgConfig> orgConfigCache;
    private static Map<String, Map<String, RequestTypeConfig>> requestTypeCacheByOrg;
    private static Map<String, Map<String, AssignmentTargetConfig>> assignmentTargetCacheByOrg;
    private static Map<String, Map<String, List<RoutingRuleConfig>>> routingRulesCacheByOrgAndRequestType;
    private static Map<String, Map<String, IncidentTemplateConfig>> incidentTemplateCacheByOrg;
    private static Map<String, EndpointConfig> endpointConfigCache;

    public class OrgConfig {
        public String developerName, orgKey, salesforceOrgId, businessUnit, environment, defaultRequestTypeKey, endpointConfigKey;
        public Boolean isActive;
        public OrgConfig(SN_Org_Config__mdt r){ developerName=r.DeveloperName; orgKey=r.Org_Key__c; salesforceOrgId=r.Salesforce_Org_Id__c; businessUnit=r.Business_Unit__c; environment=r.Environment__c; isActive=r.Is_Active__c; defaultRequestTypeKey=r.Default_Request_Type__c; endpointConfigKey=r.Endpoint_Config_Key__c; }
    }
    public class RequestTypeConfig {
        public String developerName, orgKey, requestTypeKey, sourceObject, operationMode, incidentTemplateKey, routingKey;
        public Boolean isActive;
        public RequestTypeConfig(SN_Request_Type__mdt r){ developerName=r.DeveloperName; orgKey=r.Org_Key__c; requestTypeKey=r.Request_Type_Key__c; sourceObject=r.Source_Object__c; operationMode=r.Operation_Mode__c; incidentTemplateKey=r.Incident_Template_Key__c; routingKey=r.Routing_Key__c; isActive=r.Is_Active__c; }
    }
    public class RoutingRuleConfig {
        public String developerName, orgKey, requestTypeKey, matchCriteria, assignmentTargetKey;
        public Integer priority; public Boolean isActive, isDefault;
        public RoutingRuleConfig(SN_Routing_Rule__mdt r){ developerName=r.DeveloperName; orgKey=r.Org_Key__c; requestTypeKey=r.Request_Type_Key__c; matchCriteria=r.Match_Criteria__c; assignmentTargetKey=r.Assignment_Target_Key__c; priority=r.Priority__c==null?null:Integer.valueOf(r.Priority__c); isActive=r.Is_Active__c; isDefault=r.Is_Default__c; }
    }
    public class AssignmentTargetConfig {
        public String developerName, orgKey, assignmentTargetKey, assignmentType, externalAssignmentId, displayName; public Boolean isActive;
        public AssignmentTargetConfig(SN_Assignment_Target__mdt r){ developerName=r.DeveloperName; orgKey=r.Org_Key__c; assignmentTargetKey=r.Assignment_Target_Key__c; assignmentType=r.Assignment_Type__c; externalAssignmentId=r.External_Assignment_Id__c; displayName=r.Display_Name__c; isActive=r.Is_Active__c; }
    }
    public class IncidentTemplateConfig {
        public String developerName, orgKey, templateKey, category, subcategory, impact, urgency, shortDescriptionTemplate; public Boolean isActive;
        public IncidentTemplateConfig(SN_Incident_Template__mdt r){ developerName=r.DeveloperName; orgKey=r.Org_Key__c; templateKey=r.Incident_Template_Key__c; category=r.Category__c; subcategory=r.Subcategory__c; impact=r.Impact__c; urgency=r.Urgency__c; shortDescriptionTemplate=r.Short_Description_Template__c; isActive=r.Is_Active__c; }
    }
    public class EndpointConfig {
        public String developerName, endpointConfigKey, namedCredential, basePath; public Integer timeoutMs; public Boolean isActive;
        public EndpointConfig(SN_Endpoint_Config__mdt r){ developerName=r.DeveloperName; endpointConfigKey=r.Endpoint_Config_Key__c; namedCredential=r.Named_Credential__c; basePath=r.Base_Path__c; timeoutMs=r.Timeout_Ms__c==null?null:Integer.valueOf(r.Timeout_Ms__c); isActive=r.Is_Active__c; }
    }
    public class ConfigBundle {
        public OrgConfig orgConfig; public RequestTypeConfig requestTypeConfig; public List<RoutingRuleConfig> routingRules; public Map<String, AssignmentTargetConfig> assignmentTargetsByKey;
        public ConfigBundle(OrgConfig o, RequestTypeConfig r, List<RoutingRuleConfig> rr, Map<String, AssignmentTargetConfig> at){ orgConfig=o; requestTypeConfig=r; routingRules=rr; assignmentTargetsByKey=at; }
    }

    public static SN_Org_Config__mdt getOrgConfig(String orgKey){ OrgConfig c=getOrgConfigWrapper(orgKey); return c==null?null:findOrgConfigRecord(orgKey); }
    public static OrgConfig getOrgConfigWrapper(String orgKey){ if(String.isBlank(orgKey)) return null; ensureOrgCache(); return orgConfigCache.get(orgKey); }
    public static SN_Request_Type__mdt getRequestTypeConfig(String orgKey, String requestTypeKey){ RequestTypeConfig c=getRequestTypeConfigWrapper(orgKey, requestTypeKey); return c==null?null:findRequestTypeRecord(orgKey,c.requestTypeKey); }
    public static RequestTypeConfig getRequestTypeConfigWrapper(String orgKey, String requestTypeKey){ if(String.isBlank(requestTypeKey)){ OrgConfig o=getOrgConfigWrapper(orgKey); requestTypeKey=o==null?null:o.defaultRequestTypeKey; } if(String.isBlank(requestTypeKey)) return null; ensureRequestTypeCache(); return getScopedValue(requestTypeCacheByOrg, orgKey, requestTypeKey); }
    public static List<RoutingRuleConfig> getRoutingRules(String orgKey, String requestTypeKey){ ensureRoutingRulesCache(); String effective=requestTypeKey; if(String.isBlank(effective)){ RequestTypeConfig r=getRequestTypeConfigWrapper(orgKey, null); effective=r==null?null:r.requestTypeKey; } if(String.isBlank(effective)) return new List<RoutingRuleConfig>(); return getScopedRoutingRules(orgKey,effective); }
    public static AssignmentTargetConfig getAssignmentTarget(String orgKey, String assignmentTargetKey){ if(String.isBlank(assignmentTargetKey)) return null; ensureAssignmentTargetCache(); return getScopedValue(assignmentTargetCacheByOrg, orgKey, assignmentTargetKey); }
    public static IncidentTemplateConfig getIncidentTemplate(String orgKey, String templateKey){ if(String.isBlank(templateKey)) return null; ensureIncidentTemplateCache(); return getScopedValue(incidentTemplateCacheByOrg, orgKey, templateKey); }
    public static EndpointConfig getEndpointConfig(String endpointConfigKey){ if(String.isBlank(endpointConfigKey)) return null; ensureEndpointConfigCache(); return endpointConfigCache.get(endpointConfigKey); }
    public static ConfigBundle getBundle(String orgKey, String requestTypeKey){ OrgConfig orgConfig=getOrgConfigWrapper(orgKey); RequestTypeConfig requestTypeConfig=getRequestTypeConfigWrapper(orgKey, requestTypeKey); List<RoutingRuleConfig> routingRules=getRoutingRules(orgKey, requestTypeConfig==null?requestTypeKey:requestTypeConfig.requestTypeKey); Map<String, AssignmentTargetConfig> targetsByKey=new Map<String, AssignmentTargetConfig>(); for(RoutingRuleConfig rule:routingRules){ AssignmentTargetConfig target=getAssignmentTarget(orgKey, rule.assignmentTargetKey); if(target!=null) targetsByKey.put(target.assignmentTargetKey,target);} return new ConfigBundle(orgConfig,requestTypeConfig,routingRules,targetsByKey); }

    @TestVisible static void setTestData(List<SN_Org_Config__mdt> orgConfigs, List<SN_Request_Type__mdt> requestTypes, List<SN_Routing_Rule__mdt> routingRules, List<SN_Assignment_Target__mdt> assignmentTargets){ setExtendedTestData(orgConfigs, requestTypes, routingRules, assignmentTargets, null, null); }
    @TestVisible static void setExtendedTestData(List<SN_Org_Config__mdt> orgConfigs, List<SN_Request_Type__mdt> requestTypes, List<SN_Routing_Rule__mdt> routingRules, List<SN_Assignment_Target__mdt> assignmentTargets, List<SN_Incident_Template__mdt> incidentTemplates, List<SN_Endpoint_Config__mdt> endpointConfigs){ orgConfigOverrides=orgConfigs; requestTypeOverrides=requestTypes; routingRuleOverrides=routingRules; assignmentTargetOverrides=assignmentTargets; incidentTemplateOverrides=incidentTemplates; endpointConfigOverrides=endpointConfigs; resetCaches(); }
    @TestVisible static void resetCaches(){ orgConfigCache=null; requestTypeCacheByOrg=null; assignmentTargetCacheByOrg=null; routingRulesCacheByOrgAndRequestType=null; incidentTemplateCacheByOrg=null; endpointConfigCache=null; }

    private static void ensureOrgCache(){ if(orgConfigCache!=null) return; orgConfigCache=new Map<String, OrgConfig>(); for(SN_Org_Config__mdt r:getOrgConfigRecords()){ if(r.Is_Active__c==true && !String.isBlank(r.Org_Key__c)) orgConfigCache.put(r.Org_Key__c,new OrgConfig(r)); } }
    private static void ensureRequestTypeCache(){ if(requestTypeCacheByOrg!=null) return; requestTypeCacheByOrg=new Map<String, Map<String, RequestTypeConfig>>(); for(SN_Request_Type__mdt r:getRequestTypeRecords()){ if(r.Is_Active__c==true && !String.isBlank(r.Request_Type_Key__c)) putScopedRequestType(requestTypeCacheByOrg,r.Org_Key__c,r.Request_Type_Key__c,new RequestTypeConfig(r)); } }
    private static void ensureAssignmentTargetCache(){ if(assignmentTargetCacheByOrg!=null) return; assignmentTargetCacheByOrg=new Map<String, Map<String, AssignmentTargetConfig>>(); for(SN_Assignment_Target__mdt r:getAssignmentTargetRecords()){ if(r.Is_Active__c==true && !String.isBlank(r.Assignment_Target_Key__c)) putScopedAssignmentTarget(assignmentTargetCacheByOrg,r.Org_Key__c,r.Assignment_Target_Key__c,new AssignmentTargetConfig(r)); } }
    private static void ensureIncidentTemplateCache(){ if(incidentTemplateCacheByOrg!=null) return; incidentTemplateCacheByOrg=new Map<String, Map<String, IncidentTemplateConfig>>(); for(SN_Incident_Template__mdt r:getIncidentTemplateRecords()){ if(r.Is_Active__c==true && !String.isBlank(r.Incident_Template_Key__c)) putScopedIncidentTemplate(incidentTemplateCacheByOrg,r.Org_Key__c,r.Incident_Template_Key__c,new IncidentTemplateConfig(r)); } }
    private static void ensureEndpointConfigCache(){ if(endpointConfigCache!=null) return; endpointConfigCache=new Map<String, EndpointConfig>(); for(SN_Endpoint_Config__mdt r:getEndpointConfigRecords()){ if(r.Is_Active__c==true && !String.isBlank(r.Endpoint_Config_Key__c)) endpointConfigCache.put(r.Endpoint_Config_Key__c,new EndpointConfig(r)); } }
    private static void ensureRoutingRulesCache(){ if(routingRulesCacheByOrgAndRequestType!=null) return; routingRulesCacheByOrgAndRequestType=new Map<String, Map<String, List<RoutingRuleConfig>>>(); for(SN_Routing_Rule__mdt r:getRoutingRuleRecords()){ if(r.Is_Active__c==true && !String.isBlank(r.Request_Type_Key__c)){ String scope=scopedKey(r.Org_Key__c); if(!routingRulesCacheByOrgAndRequestType.containsKey(scope)) routingRulesCacheByOrgAndRequestType.put(scope,new Map<String, List<RoutingRuleConfig>>()); Map<String, List<RoutingRuleConfig>> byType=routingRulesCacheByOrgAndRequestType.get(scope); if(!byType.containsKey(r.Request_Type_Key__c)) byType.put(r.Request_Type_Key__c,new List<RoutingRuleConfig>()); byType.get(r.Request_Type_Key__c).add(new RoutingRuleConfig(r)); } } for(Map<String, List<RoutingRuleConfig>> scopedRules:routingRulesCacheByOrgAndRequestType.values()) for(String requestTypeKey:scopedRules.keySet()) scopedRules.get(requestTypeKey).sort(new RoutingRuleComparator()); }
    private class RoutingRuleComparator implements System.Comparator<RoutingRuleConfig> { public Integer compare(RoutingRuleConfig a, RoutingRuleConfig b){ Integer left=a.priority==null?Integer.MAX_VALUE:a.priority; Integer right=b.priority==null?Integer.MAX_VALUE:b.priority; if(left==right) return String.valueOf(a.developerName).compareToIgnoreCase(String.valueOf(b.developerName)); return left<right?-1:1; } }
    private static List<RoutingRuleConfig> getScopedRoutingRules(String orgKey, String requestTypeKey){ List<RoutingRuleConfig> results=new List<RoutingRuleConfig>(); for(String scope:new List<String>{scopedKey(orgKey),scopedKey(null)}){ Map<String, List<RoutingRuleConfig>> byType=routingRulesCacheByOrgAndRequestType.get(scope); if(byType!=null && byType.containsKey(requestTypeKey)) results.addAll(byType.get(requestTypeKey)); } return results; }
    private static void putScopedRequestType(Map<String, Map<String, RequestTypeConfig>> cache, String orgKey, String key, RequestTypeConfig value){ String scope=scopedKey(orgKey); if(!cache.containsKey(scope)) cache.put(scope,new Map<String, RequestTypeConfig>()); cache.get(scope).put(key,value); }
    private static void putScopedAssignmentTarget(Map<String, Map<String, AssignmentTargetConfig>> cache, String orgKey, String key, AssignmentTargetConfig value){ String scope=scopedKey(orgKey); if(!cache.containsKey(scope)) cache.put(scope,new Map<String, AssignmentTargetConfig>()); cache.get(scope).put(key,value); }
    private static void putScopedIncidentTemplate(Map<String, Map<String, IncidentTemplateConfig>> cache, String orgKey, String key, IncidentTemplateConfig value){ String scope=scopedKey(orgKey); if(!cache.containsKey(scope)) cache.put(scope,new Map<String, IncidentTemplateConfig>()); cache.get(scope).put(key,value); }
    private static String scopedKey(String orgKey){ return String.isBlank(orgKey)?'__GLOBAL__':orgKey; }
    public static List<SN_Org_Config__mdt> getOrgConfigRecords(){ if(Test.isRunningTest() && orgConfigOverrides!=null) return orgConfigOverrides; return [SELECT DeveloperName, Org_Key__c, Salesforce_Org_Id__c, Business_Unit__c, Environment__c, Is_Active__c, Default_Request_Type__c, Endpoint_Config_Key__c FROM SN_Org_Config__mdt]; }
    public static List<SN_Request_Type__mdt> getRequestTypeRecords(){ if(Test.isRunningTest() && requestTypeOverrides!=null) return requestTypeOverrides; return [SELECT DeveloperName, Org_Key__c, Request_Type_Key__c, Source_Object__c, Operation_Mode__c, Incident_Template_Key__c, Routing_Key__c, Is_Active__c FROM SN_Request_Type__mdt]; }
    public static List<SN_Routing_Rule__mdt> getRoutingRuleRecords(){ if(Test.isRunningTest() && routingRuleOverrides!=null) return routingRuleOverrides; return [SELECT DeveloperName, Org_Key__c, Request_Type_Key__c, Match_Criteria__c, Assignment_Target_Key__c, Priority__c, Is_Active__c, Is_Default__c FROM SN_Routing_Rule__mdt]; }
    public static List<SN_Assignment_Target__mdt> getAssignmentTargetRecords(){ if(Test.isRunningTest() && assignmentTargetOverrides!=null) return assignmentTargetOverrides; return [SELECT DeveloperName, Org_Key__c, Assignment_Target_Key__c, Assignment_Type__c, External_Assignment_Id__c, Display_Name__c, Is_Active__c FROM SN_Assignment_Target__mdt]; }
    public static List<SN_Incident_Template__mdt> getIncidentTemplateRecords(){ if(Test.isRunningTest() && incidentTemplateOverrides!=null) return incidentTemplateOverrides; return [SELECT DeveloperName, Org_Key__c, Incident_Template_Key__c, Category__c, Subcategory__c, Impact__c, Urgency__c, Short_Description_Template__c, Is_Active__c FROM SN_Incident_Template__mdt]; }
    public static List<SN_Endpoint_Config__mdt> getEndpointConfigRecords(){ if(Test.isRunningTest() && endpointConfigOverrides!=null) return endpointConfigOverrides; return [SELECT DeveloperName, Endpoint_Config_Key__c, Named_Credential__c, Base_Path__c, Timeout_Ms__c, Is_Active__c FROM SN_Endpoint_Config__mdt]; }
    private static SN_Org_Config__mdt findOrgConfigRecord(String orgKey){ for(SN_Org_Config__mdt r:getOrgConfigRecords()) if(r.Org_Key__c==orgKey && r.Is_Active__c==true) return r; return null; }
    private static SN_Request_Type__mdt findRequestTypeRecord(String orgKey, String requestTypeKey){ for(SN_Request_Type__mdt r:getRequestTypeRecords()) if(r.Request_Type_Key__c==requestTypeKey && r.Is_Active__c==true && (r.Org_Key__c==orgKey || String.isBlank(r.Org_Key__c))) return r; return null; }
    private static IncidentTemplateConfig getScopedValue(Map<String, Map<String, IncidentTemplateConfig>> cache, String orgKey, String key){ for(String scope:new List<String>{scopedKey(orgKey),scopedKey(null)}) if(cache.containsKey(scope) && cache.get(scope).containsKey(key)) return cache.get(scope).get(key); return null; }
    private static RequestTypeConfig getScopedValue(Map<String, Map<String, RequestTypeConfig>> cache, String orgKey, String key){ for(String scope:new List<String>{scopedKey(orgKey),scopedKey(null)}) if(cache.containsKey(scope) && cache.get(scope).containsKey(key)) return cache.get(scope).get(key); return null; }
    private static AssignmentTargetConfig getScopedValue(Map<String, Map<String, AssignmentTargetConfig>> cache, String orgKey, String key){ for(String scope:new List<String>{scopedKey(orgKey),scopedKey(null)}) if(cache.containsKey(scope) && cache.get(scope).containsKey(key)) return cache.get(scope).get(key); return null; }
}
