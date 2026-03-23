public with sharing class SN_CaseIntakeController {
    public static Id submitCaseForIncident(Id caseId, String requestTypeKey) {
        validateCaseForSubmission(caseId, requestTypeKey);
        String orgKey = 'DEFAULT';
        return SN_IncidentOrchestrationService.enqueueCaseIncident(caseId, requestTypeKey, orgKey, 'intakeSubmission');
    }

    public static void validateCaseForSubmission(Id caseId) {
        validateCaseForSubmission(caseId, null);
    }

    public static void validateCaseForSubmission(Id caseId, String requestTypeKey) {
        if (caseId == null) {
            throw new IntakeValidationException('Case Id is required.');
        }
        Case caseRecord = [SELECT Id, Subject, Origin FROM Case WHERE Id = :caseId LIMIT 1];
        if (String.isBlank(caseRecord.Subject)) {
            throw new IntakeValidationException('Case Subject is required before ServiceNow submission.');
        }
        if (String.isBlank(caseRecord.Origin)) {
            throw new IntakeValidationException('Case Origin is required before ServiceNow submission.');
        }
        SN_CaseIntakeSupport.RequestTypeDescriptor descriptor = SN_CaseIntakeSupport.describeRequestType('DEFAULT', requestTypeKey);
        if (descriptor == null) {
            throw new IntakeValidationException('No active intake request type is configured for this Case submission.');
        }
        if (descriptor.supportedSourceObject != 'Case') {
            throw new IntakeValidationException('The configured request type does not support Case intake.');
        }
    }

    public class IntakeValidationException extends Exception {}
}
