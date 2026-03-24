public with sharing class SN_PayloadValidationService {
    public class ValidationResult {
        public Boolean valid;
        public String code;
        public String message;
        public String safeSummary;

        public ValidationResult(Boolean valid, String code, String message, String safeSummary) {
            this.valid = valid;
            this.code = code;
            this.message = message;
            this.safeSummary = safeSummary;
        }
    }

    public static ValidationResult validateIncidentCreate(String orgKey, String requestTypeKey, Map<String, Object> payload) {
        if (String.isBlank(orgKey)) {
            return fail('ORG_KEY_REQUIRED', 'Org key is required for outbound payload validation.', 'missingOrgKey');
        }
        SN_ConfigService.RequestTypeConfig requestType = SN_ConfigService.getRequestTypeConfigWrapper(orgKey, requestTypeKey);
        if (requestType == null || String.isBlank(requestType.requestTypeKey)) {
            return fail('REQUEST_TYPE_UNSUPPORTED', 'Request type is not configured for outbound payload.', 'unsupportedRequestType');
        }
        List<SN_FieldMappingService.FieldMappingRule> mappingRules = SN_FieldMappingService.getActiveMappingRules(orgKey, requestType.requestTypeKey);
        if (mappingRules.isEmpty()) {
            return fail('MAPPING_INCOMPLETE', 'No active field mappings found for outbound payload.', 'missingFieldMappings');
        }
        if (payload == null || payload.isEmpty()) {
            return fail('PAYLOAD_REQUIRED', 'Outbound payload must contain at least one field.', 'payloadEmpty');
        }

        for (String requiredField : new List<String>{ 'short_description', 'u_salesforce_case_id' }) {
            if (!payload.containsKey(requiredField) || payload.get(requiredField) == null || String.isBlank(String.valueOf(payload.get(requiredField)))) {
                return fail('REQUIRED_FIELD_MISSING', 'Payload is missing required field: ' + requiredField + '.', 'requiredFieldMissing=' + requiredField);
            }
        }

        for (String prohibitedNullField : new List<String>{ 'assignment_group', 'short_description' }) {
            if (payload.containsKey(prohibitedNullField) && payload.get(prohibitedNullField) == null) {
                return fail('PROHIBITED_NULL', 'Payload contains prohibited null field: ' + prohibitedNullField + '.', 'prohibitedNull=' + prohibitedNullField);
            }
        }

        return new ValidationResult(true, null, null, 'payloadValidated');
    }

    private static ValidationResult fail(String code, String message, String safeSummary) {
        return new ValidationResult(false, code, message, safeSummary);
    }
}
