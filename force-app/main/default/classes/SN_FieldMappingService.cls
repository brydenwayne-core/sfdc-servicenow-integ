public with sharing class SN_FieldMappingService {
    @TestVisible
    private static List<SN_Field_Mapping__mdt> mappingOverrides;
    private static Map<String, Map<String, List<FieldMappingRule>>> mappingsByOrgAndRequestType;

    public class FieldMappingRule {
        public String developerName;
        public String orgKey;
        public String requestTypeKey;
        public String sourceFieldApi;
        public String targetFieldApi;
        public String transformStrategy;
        public String staticValue;
        public Integer sequence;
        public Boolean isActive;

        public FieldMappingRule(SN_Field_Mapping__mdt record) {
            developerName = record.DeveloperName;
            orgKey = record.Org_Key__c;
            requestTypeKey = record.Request_Type_Key__c;
            sourceFieldApi = record.Source_Field_API__c;
            targetFieldApi = record.Target_Field_API__c;
            transformStrategy = record.Transform_Strategy__c;
            staticValue = record.Static_Value__c;
            sequence = record.Sequence__c == null ? null : Integer.valueOf(record.Sequence__c);
            isActive = record.Is_Active__c;
        }
    }

    public class MappingContext {
        public String orgKey;
        public String requestTypeKey;
        public SObject sourceRecord;
        public Map<String, Object> relatedData;

        public MappingContext(String orgKey, String requestTypeKey, SObject sourceRecord, Map<String, Object> relatedData) {
            this.orgKey = orgKey;
            this.requestTypeKey = requestTypeKey;
            this.sourceRecord = sourceRecord;
            this.relatedData = relatedData == null ? new Map<String, Object>() : relatedData;
        }
    }

    public class IncidentPayload {
        public Map<String, Object> fields { get; private set; }

        public IncidentPayload() {
            fields = new Map<String, Object>();
        }

        public void put(String key, Object value) {
            fields.put(key, value);
        }
    }

    /** Resolves metadata-driven field mappings for the supplied org and request type context. */
    public static List<SN_Field_Mapping__mdt> getActiveMappings(String orgKey, String requestTypeKey) {
        List<SN_Field_Mapping__mdt> results = new List<SN_Field_Mapping__mdt>();
        for (SN_Field_Mapping__mdt record : getRecords()) {
            if (record.Is_Active__c == true && record.Request_Type_Key__c == requestTypeKey &&
                (record.Org_Key__c == orgKey || String.isBlank(record.Org_Key__c))) {
                results.add(record);
            }
        }
        results.sort(new FieldMappingMetadataComparator());
        return results;
    }

    public static List<FieldMappingRule> getActiveMappingRules(String orgKey, String requestTypeKey) {
        ensureCache();
        List<FieldMappingRule> results = new List<FieldMappingRule>();
        for (String scope : new List<String>{ scopedKey(null), scopedKey(orgKey) }) {
            Map<String, List<FieldMappingRule>> byRequestType = mappingsByOrgAndRequestType.get(scope);
            if (byRequestType != null && byRequestType.containsKey(requestTypeKey)) {
                results.addAll(byRequestType.get(requestTypeKey));
            }
        }
        results.sort(new MappingRuleComparator());
        return results;
    }

    /** Produces a normalized outbound field map from the source record and active mapping metadata. */
    public static Map<String, Object> mapSourceToTarget(SObject sourceRecord, List<SN_Field_Mapping__mdt> mappings) {
        MappingContext context = new MappingContext(null, null, sourceRecord, null);
        List<FieldMappingRule> rules = new List<FieldMappingRule>();
        for (SN_Field_Mapping__mdt mapping : mappings) {
            rules.add(new FieldMappingRule(mapping));
        }
        return applyRules(context, rules).fields;
    }

    public static IncidentPayload buildIncidentPayload(String orgKey, String requestTypeKey, Case caseRecord, Map<String, Object> relatedData) {
        MappingContext context = new MappingContext(orgKey, requestTypeKey, caseRecord, relatedData);
        return applyRules(context, getActiveMappingRules(orgKey, requestTypeKey));
    }

    @TestVisible
    static void setTestData(List<SN_Field_Mapping__mdt> mappings) {
        mappingOverrides = mappings;
        mappingsByOrgAndRequestType = null;
    }

    @TestVisible
    static void resetCache() {
        mappingsByOrgAndRequestType = null;
    }

    private static IncidentPayload applyRules(MappingContext context, List<FieldMappingRule> rules) {
        IncidentPayload payload = new IncidentPayload();
        for (FieldMappingRule rule : rules) {
            if (String.isBlank(rule.targetFieldApi)) {
                continue;
            }
            Object rawValue = resolveSourceValue(context, rule);
            Object transformedValue = applyTransform(rule, rawValue, context);
            if (transformedValue != null) {
                payload.put(rule.targetFieldApi, transformedValue);
            }
        }
        return payload;
    }

    private static Object resolveSourceValue(MappingContext context, FieldMappingRule rule) {
        if ('Static Value' == rule.transformStrategy) {
            return rule.staticValue;
        }
        if (String.isBlank(rule.sourceFieldApi)) {
            return null;
        }
        List<String> parts = rule.sourceFieldApi.split('\\.');
        if (parts.isEmpty()) {
            return null;
        }

        if (parts[0] == 'Case') {
            return traversePath(context.sourceRecord, parts, 1);
        }
        if (context.relatedData != null && context.relatedData.containsKey(parts[0])) {
            Object currentValue = context.relatedData.get(parts[0]);
            return traversePath(currentValue, parts, 1);
        }
        return null;
    }

    private static Object traversePath(Object currentValue, List<String> parts, Integer startIndex) {
        for (Integer i = startIndex; i < parts.size() && currentValue != null; i++) {
            String part = parts[i];
            if (currentValue instanceof SObject) {
                currentValue = ((SObject) currentValue).get(part);
            } else if (currentValue instanceof Map<String, Object>) {
                currentValue = ((Map<String, Object>) currentValue).get(part);
            } else {
                return null;
            }
        }
        return currentValue;
    }

    private static Object applyTransform(FieldMappingRule rule, Object rawValue, MappingContext context) {
        String strategy = String.isBlank(rule.transformStrategy) ? 'Direct' : rule.transformStrategy;
        if ('Static Value' == strategy) {
            return rule.staticValue;
        }
        if (rawValue == null) {
            return null;
        }
        String textValue = String.valueOf(rawValue);
        if ('Uppercase' == strategy) {
            return textValue.toUpperCase();
        }
        if ('Lowercase' == strategy) {
            return textValue.toLowerCase();
        }
        if ('Trim' == strategy) {
            return textValue.trim();
        }
        if ('Org Key' == strategy) {
            return context.orgKey;
        }
        if ('Request Type Key' == strategy) {
            return context.requestTypeKey;
        }
        return rawValue;
    }

    private static void ensureCache() {
        if (mappingsByOrgAndRequestType != null) {
            return;
        }
        mappingsByOrgAndRequestType = new Map<String, Map<String, List<FieldMappingRule>>>();
        for (SN_Field_Mapping__mdt record : getRecords()) {
            if (record.Is_Active__c != true || String.isBlank(record.Request_Type_Key__c)) {
                continue;
            }
            String scope = scopedKey(record.Org_Key__c);
            if (!mappingsByOrgAndRequestType.containsKey(scope)) {
                mappingsByOrgAndRequestType.put(scope, new Map<String, List<FieldMappingRule>>());
            }
            if (!mappingsByOrgAndRequestType.get(scope).containsKey(record.Request_Type_Key__c)) {
                mappingsByOrgAndRequestType.get(scope).put(record.Request_Type_Key__c, new List<FieldMappingRule>());
            }
            mappingsByOrgAndRequestType.get(scope).get(record.Request_Type_Key__c).add(new FieldMappingRule(record));
        }
    }


    private class FieldMappingMetadataComparator implements System.Comparator<SN_Field_Mapping__mdt> {
        public Integer compare(SN_Field_Mapping__mdt a, SN_Field_Mapping__mdt b) {
            Integer left = a.Sequence__c == null ? Integer.MAX_VALUE : Integer.valueOf(a.Sequence__c);
            Integer right = b.Sequence__c == null ? Integer.MAX_VALUE : Integer.valueOf(b.Sequence__c);
            if (left == right) {
                return String.valueOf(a.DeveloperName).compareToIgnoreCase(String.valueOf(b.DeveloperName));
            }
            return left < right ? -1 : 1;
        }
    }

    private class MappingRuleComparator implements System.Comparator<FieldMappingRule> {
        public Integer compare(FieldMappingRule a, FieldMappingRule b) {
            Integer left = a.sequence == null ? Integer.MAX_VALUE : a.sequence;
            Integer right = b.sequence == null ? Integer.MAX_VALUE : b.sequence;
            if (left == right) {
                return String.valueOf(a.developerName).compareToIgnoreCase(String.valueOf(b.developerName));
            }
            return left < right ? -1 : 1;
        }
    }

    private static List<SN_Field_Mapping__mdt> getRecords() {
        if (Test.isRunningTest() && mappingOverrides != null) {
            return mappingOverrides;
        }
        return [
            SELECT DeveloperName, Org_Key__c, Request_Type_Key__c, Source_Field_API__c, Target_Field_API__c,
                Transform_Strategy__c, Static_Value__c, Sequence__c, Is_Active__c
            FROM SN_Field_Mapping__mdt
        ];
    }

    private static String scopedKey(String orgKey) {
        return String.isBlank(orgKey) ? '__GLOBAL__' : orgKey;
    }
}
