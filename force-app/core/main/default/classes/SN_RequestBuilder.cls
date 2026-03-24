public with sharing class SN_RequestBuilder {
    /** Builds the outbound ServiceNow request payload from normalized integration context and mapped fields. */
    public static Map<String, Object> buildIncidentRequest(Id caseId, String orgKey, String requestTypeKey, String assignmentKey) {
        if (caseId == null) {
            throw new RequestBuilderException('Case Id is required.');
        }
        List<Case> records = [
            SELECT Id, Subject, Description, Priority
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        if (records.isEmpty()) {
            throw new RequestBuilderException('Case not found for id ' + caseId + '.');
        }
        Map<String, Object> payload = SN_FieldMappingService.buildIncidentPayload(orgKey, requestTypeKey, records[0], null).fields;
        payload.put('u_salesforce_case_id', caseId);
        if (!String.isBlank(assignmentKey)) {
            SN_ConfigService.AssignmentTargetConfig assignmentTarget = SN_ConfigService.getAssignmentTarget(orgKey, assignmentKey);
            if (assignmentTarget != null && !String.isBlank(assignmentTarget.externalAssignmentId)) {
                payload.put('assignment_group', assignmentTarget.externalAssignmentId);
            }
        }
        return payload;
    }

    public class RequestBuilderException extends Exception {}
}
