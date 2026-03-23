public with sharing class SN_RoutingService {
    @TestVisible
    private static final String DEFAULT_TEMPLATE_SENTINEL = '__REQUEST_TYPE_DEFAULT__';

    public class RoutingContext {
        public String orgKey;
        public String requestTypeKey;
        public String category;
        public String subcategory;
        public Map<String, Object> metadata;

        public RoutingContext() {
            metadata = new Map<String, Object>();
        }
    }

    public class RoutingOutcome {
        public String assignmentTargetKey;
        public SN_ConfigService.AssignmentTargetConfig assignmentTarget;
        public String incidentTemplateKey;
        public String priorityBehavior;
        public Boolean stopDownstreamProcessing;
        public Boolean syncComments;
        public Boolean syncFiles;
        public String matchedRuleDeveloperName;
        public Boolean usedFallback;
        public Integer matchedRulePriority;
    }

    private class RuleEnvelope {
        public SN_ConfigService.RoutingRuleConfig rule;
        public Map<String, Object> whenClause;
        public Map<String, Object> thenClause;
    }

    /** Resolves the target assignment and routing outcome for the current transaction context. */
    public static String resolveAssignmentKey(String orgKey, String requestTypeKey, SObject sourceRecord) {
        RoutingContext context = new RoutingContext();
        context.orgKey = orgKey;
        context.requestTypeKey = requestTypeKey;
        if (sourceRecord != null) {
            context.category = stringify(sourceRecord.get('Category'));
            context.subcategory = stringify(sourceRecord.get('Subcategory'));
        }
        RoutingOutcome outcome = resolve(context);
        return outcome == null ? null : outcome.assignmentTargetKey;
    }

    public static RoutingOutcome resolve(RoutingContext context) {
        if (context == null || String.isBlank(context.orgKey)) {
            return null;
        }

        SN_ConfigService.RequestTypeConfig requestType = SN_ConfigService.getRequestTypeConfigWrapper(context.orgKey, context.requestTypeKey);
        String effectiveRequestTypeKey = requestType == null ? context.requestTypeKey : requestType.requestTypeKey;
        if (String.isBlank(effectiveRequestTypeKey)) {
            return null;
        }

        List<RuleEnvelope> candidates = new List<RuleEnvelope>();
        RuleEnvelope defaultRule;
        for (SN_ConfigService.RoutingRuleConfig rule : SN_ConfigService.getRoutingRules(context.orgKey, effectiveRequestTypeKey)) {
            RuleEnvelope envelope = buildEnvelope(rule);
            if (rule.isDefault == true) {
                if (defaultRule == null) {
                    defaultRule = envelope;
                }
                continue;
            }
            if (matchesContext(envelope.whenClause, context)) {
                candidates.add(envelope);
            }
        }

        if (candidates.size() > 1) {
            throw new RoutingException('Conflicting routing rules matched for org ' + context.orgKey + ' and request type ' + effectiveRequestTypeKey + '.');
        }

        RuleEnvelope selected = candidates.isEmpty() ? defaultRule : candidates[0];
        if (selected == null) {
            return null;
        }
        return toOutcome(selected, context, requestType, candidates.isEmpty());
    }

    private static RuleEnvelope buildEnvelope(SN_ConfigService.RoutingRuleConfig rule) {
        RuleEnvelope envelope = new RuleEnvelope();
        envelope.rule = rule;
        envelope.whenClause = new Map<String, Object>();
        envelope.thenClause = new Map<String, Object>();
        if (String.isBlank(rule.matchCriteria)) {
            return envelope;
        }
        Object raw = JSON.deserializeUntyped(rule.matchCriteria);
        if (!(raw instanceof Map<String, Object>)) {
            return envelope;
        }
        Map<String, Object> document = (Map<String, Object>) raw;
        if (document.containsKey('when') && document.get('when') instanceof Map<String, Object>) {
            envelope.whenClause = (Map<String, Object>) document.get('when');
        }
        if (document.containsKey('then') && document.get('then') instanceof Map<String, Object>) {
            envelope.thenClause = (Map<String, Object>) document.get('then');
        }
        return envelope;
    }

    private static Boolean matchesContext(Map<String, Object> criteria, RoutingContext context) {
        if (criteria == null || criteria.isEmpty()) {
            return true;
        }
        for (String key : criteria.keySet()) {
            Object expected = criteria.get(key);
            Object actual;
            if (key == 'category') {
                actual = context.category;
            } else if (key == 'subcategory') {
                actual = context.subcategory;
            } else if (key == 'requestTypeKey') {
                actual = context.requestTypeKey;
            } else if (context.metadata != null) {
                actual = context.metadata.get(key);
            }
            if (!matchesValue(expected, actual)) {
                return false;
            }
        }
        return true;
    }

    private static Boolean matchesValue(Object expected, Object actual) {
        if (expected instanceof List<Object>) {
            for (Object option : (List<Object>) expected) {
                if (matchesValue(option, actual)) {
                    return true;
                }
            }
            return false;
        }
        return stringify(expected) == stringify(actual);
    }

    private static RoutingOutcome toOutcome(RuleEnvelope envelope, RoutingContext context,
        SN_ConfigService.RequestTypeConfig requestType, Boolean usedFallback) {
        RoutingOutcome outcome = new RoutingOutcome();
        outcome.assignmentTargetKey = String.isBlank(asString(envelope.thenClause.get('assignmentTargetKey')))
            ? envelope.rule.assignmentTargetKey : asString(envelope.thenClause.get('assignmentTargetKey'));
        outcome.assignmentTarget = SN_ConfigService.getAssignmentTarget(context.orgKey, outcome.assignmentTargetKey);
        outcome.incidentTemplateKey = deriveTemplateKey(envelope.thenClause, requestType);
        outcome.priorityBehavior = blankToNull(asString(envelope.thenClause.get('priorityBehavior')));
        outcome.stopDownstreamProcessing = asBoolean(envelope.thenClause.get('stopDownstreamProcessing'));
        outcome.syncComments = asBoolean(envelope.thenClause.get('syncComments'));
        outcome.syncFiles = asBoolean(envelope.thenClause.get('syncFiles'));
        outcome.matchedRuleDeveloperName = envelope.rule.developerName;
        outcome.usedFallback = usedFallback;
        outcome.matchedRulePriority = envelope.rule.priority;
        return outcome;
    }

    private static String deriveTemplateKey(Map<String, Object> thenClause, SN_ConfigService.RequestTypeConfig requestType) {
        String overrideKey = asString(thenClause.get('incidentTemplateKey'));
        if (String.isBlank(overrideKey) || overrideKey == DEFAULT_TEMPLATE_SENTINEL) {
            return requestType == null ? null : requestType.incidentTemplateKey;
        }
        return overrideKey;
    }

    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static String blankToNull(String value) {
        return String.isBlank(value) ? null : value;
    }

    private static Boolean asBoolean(Object value) {
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        return String.valueOf(value).toLowerCase() == 'true';
    }

    private static String stringify(Object value) {
        return value == null ? null : String.valueOf(value).trim().toLowerCase();
    }

    public class RoutingException extends Exception {}
}
