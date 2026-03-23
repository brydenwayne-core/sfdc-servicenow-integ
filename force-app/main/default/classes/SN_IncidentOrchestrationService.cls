public with sharing class SN_IncidentOrchestrationService {
    public static Id orchestrateCaseIncident(Id caseId, String requestTypeKey) {
        SN_IntegrationOrchestrator.RequestContext context = new SN_IntegrationOrchestrator.RequestContext();
        context.requestTypeKey = requestTypeKey;
        return SN_IntegrationOrchestrator.orchestrate(caseId, context).transactionId;
    }

    public static Id enqueueCaseIncident(Id caseId, String requestTypeKey, String orgKey, String businessContext) {
        return System.enqueueJob(new SN_IncidentSyncQueueable(caseId, requestTypeKey, orgKey, businessContext));
    }

    public static Id enqueueFileSync(Id caseId, Id contentVersionId, String incidentSysId, String orgKey, String requestTypeKey) {
        return System.enqueueJob(new SN_FileSyncQueueable(caseId, contentVersionId, incidentSysId, orgKey, requestTypeKey));
    }

    public static void retryTransaction(Id transactionId) {
        SN_IntegrationOrchestrator.retryExistingTransaction(transactionId);
    }

    public static Id synchronizeFile(Id caseId, Id contentVersionId, String incidentSysId, String orgKey, String requestTypeKey) {
        if (caseId == null || contentVersionId == null || String.isBlank(incidentSysId) || String.isBlank(orgKey)) {
            throw new IncidentOrchestrationException('Case, file, incident, and org context are required for file synchronization.');
        }

        ContentVersion versionRecord = [
            SELECT Id, Title, FileExtension, FileType, VersionData
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];

        String businessContext = String.join(new List<String>{ orgKey, requestTypeKey, incidentSysId, String.valueOf(contentVersionId) }, '|');
        String idempotencyKey = SN_IdempotencyService.buildKey(caseId, 'syncFile', businessContext);
        String correlationId = SN_ServiceNowClient.generateCorrelationId();
        SN_IdempotencyService.ReservationResult reservation = SN_IdempotencyService.reserveTransaction(
            idempotencyKey,
            correlationId,
            orgKey,
            requestTypeKey,
            caseId,
            'syncFile'
        );
        if (!reservation.shouldProcess) {
            return reservation.transactionId;
        }

        update new Integration_Transaction__c(Id = reservation.transactionId, Status__c = 'In Progress');

        SN_ServiceNowClient.FileSyncRequest request = new SN_ServiceNowClient.FileSyncRequest();
        request.orgKey = orgKey;
        request.correlationId = correlationId;
        request.idempotencyKey = idempotencyKey;
        request.incidentSysId = incidentSysId;
        request.fileName = buildFileName(versionRecord);
        request.contentType = deriveContentType(versionRecord);
        request.base64Body = EncodingUtil.base64Encode(versionRecord.VersionData);

        SN_ServiceNowClient.ResponseEnvelope response = SN_ServiceNowClient.synchronizeFile(request);
        if (response.success == true) {
            SN_TransactionLogService.markSuccess(reservation.transactionId, incidentSysId, response.safeSummary);
            return reservation.transactionId;
        }

        SN_TransactionLogService.markFailure(
            reservation.transactionId,
            mapFailureCategory(response.failureCategory),
            response.failureCode,
            'ServiceNow file synchronization failed.',
            response.retryable,
            response.safeSummary
        );
        throw new IncidentOrchestrationException('File synchronization failed with status ' + response.statusCode + '.');
    }

    private static String buildFileName(ContentVersion versionRecord) {
        String baseName = versionRecord.Title;
        if (!String.isBlank(versionRecord.FileExtension) && !baseName.endsWith('.' + versionRecord.FileExtension)) {
            return baseName + '.' + versionRecord.FileExtension;
        }
        return baseName;
    }

    private static String deriveContentType(ContentVersion versionRecord) {
        if (String.isBlank(versionRecord.FileType)) {
            return 'application/octet-stream';
        }
        if (versionRecord.FileType == 'TXT') {
            return 'text/plain';
        }
        if (versionRecord.FileType == 'PDF') {
            return 'application/pdf';
        }
        return 'application/octet-stream';
    }

    private static String mapFailureCategory(SN_ServiceNowClient.FailureCategory failureCategory) {
        if (failureCategory == SN_ServiceNowClient.FailureCategory.CONFIGURATION) {
            return 'Configuration';
        }
        if (failureCategory == SN_ServiceNowClient.FailureCategory.FUNCTIONAL) {
            return 'Validation';
        }
        if (failureCategory == SN_ServiceNowClient.FailureCategory.AUTH) {
            return 'Security';
        }
        if (failureCategory == SN_ServiceNowClient.FailureCategory.TECHNICAL) {
            return 'Transport';
        }
        return 'Unknown';
    }

    public class IncidentOrchestrationException extends Exception {}
}
