public with sharing class SN_IntegrationOrchestrator {
    public class RequestContext {
        public String orgKey;
        public String requestTypeKey;
        public String businessContext;
        public String featureKey;
        public String operationName;

        public RequestContext() {
            operationName = 'createIncident';
            featureKey = 'CASE_TO_INCIDENT_SYNC';
        }
    }

    public class OrchestrationResult {
        public Id transactionId;
        public String idempotencyKey;
        public Boolean skippedDuplicate;
        public Boolean retryExecution;
        public String targetRecordId;
        public String status;
    }

    public interface ICaseRepository { Case load(Id caseId); }
    public interface IFeatureToggleGateway { Boolean isEnabled(String featureKey, String orgKey); }
    public interface IConfigurationGateway {
        SN_ConfigService.OrgConfig getOrgConfig(String orgKey);
        SN_ConfigService.RequestTypeConfig getRequestType(String orgKey, String requestTypeKey);
    }
    public interface IFieldMappingGateway { Map<String, Object> buildPayload(String orgKey, String requestTypeKey, Case caseRecord, Map<String, Object> relatedData); }
    public interface IRoutingGateway { SN_RoutingService.RoutingOutcome resolve(SN_RoutingService.RoutingContext context); }
    public interface IServiceNowGateway { SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request); }

    @TestVisible private static ICaseRepository caseRepository = new DefaultCaseRepository();
    @TestVisible private static IFeatureToggleGateway featureToggleGateway = new DefaultFeatureToggleGateway();
    @TestVisible private static IConfigurationGateway configurationGateway = new DefaultConfigurationGateway();
    @TestVisible private static IFieldMappingGateway fieldMappingGateway = new DefaultFieldMappingGateway();
    @TestVisible private static IRoutingGateway routingGateway = new DefaultRoutingGateway();
    @TestVisible private static IServiceNowGateway serviceNowGateway = new DefaultServiceNowGateway();

    /**
     * Legacy facade retained for backward-compatible entry points while the new layered architecture is adopted.
     */
    public static Id submitCase(Id caseId, String requestTypeKey) {
        RequestContext context = new RequestContext();
        context.requestTypeKey = requestTypeKey;
        return orchestrate(caseId, context).transactionId;
    }

    public static OrchestrationResult orchestrate(Id caseId, RequestContext context) {
        if (caseId == null) {
            throw new OrchestrationException('Case Id is required.');
        }
        Case caseRecord = caseRepository.load(caseId);
        if (caseRecord == null) {
            throw new OrchestrationException('Case not found for id ' + caseId + '.');
        }

        RequestContext effectiveContext = context == null ? new RequestContext() : context;
        String orgKey = resolveOrgKey(effectiveContext);
        if (!featureToggleGateway.isEnabled(effectiveContext.featureKey, orgKey)) {
            throw new OrchestrationException('Feature ' + effectiveContext.featureKey + ' is disabled for org ' + orgKey + '.');
        }

        SN_ConfigService.OrgConfig orgConfig = configurationGateway.getOrgConfig(orgKey);
        if (orgConfig == null) {
            throw new OrchestrationException('No active org config found for org ' + orgKey + '.');
        }

        SN_ConfigService.RequestTypeConfig requestType = configurationGateway.getRequestType(orgKey, effectiveContext.requestTypeKey);
        if (requestType == null) {
            throw new OrchestrationException('No active request type found for org ' + orgKey + '.');
        }

        String businessContext = buildBusinessContext(orgKey, requestType.requestTypeKey, effectiveContext.businessContext);
        String idempotencyKey = SN_IdempotencyService.buildKey(caseRecord.Id, effectiveContext.operationName, businessContext);
        String correlationId = SN_ServiceNowClient.generateCorrelationId();
        SN_IdempotencyService.ReservationResult reservation = SN_IdempotencyService.reserveTransaction(
            idempotencyKey,
            correlationId,
            orgKey,
            requestType.requestTypeKey,
            caseRecord.Id
        );

        OrchestrationResult result = new OrchestrationResult();
        result.transactionId = reservation.transactionId;
        result.idempotencyKey = idempotencyKey;
        result.retryExecution = reservation.retryExecution;
        result.status = reservation.status;
        result.targetRecordId = reservation.targetRecordId;
        if (!reservation.shouldProcess) {
            result.skippedDuplicate = true;
            return result;
        }

        try {
            SN_RoutingService.RoutingContext routingContext = new SN_RoutingService.RoutingContext();
            routingContext.orgKey = orgKey;
            routingContext.requestTypeKey = requestType.requestTypeKey;
            routingContext.metadata.put('origin', caseRecord.Origin);
            routingContext.metadata.put('priority', caseRecord.Priority);

            SN_RoutingService.RoutingOutcome routingOutcome = routingGateway.resolve(routingContext);
            Map<String, Object> payload = fieldMappingGateway.buildPayload(orgKey, requestType.requestTypeKey, caseRecord, null);
            if (routingOutcome != null && routingOutcome.assignmentTarget != null) {
                payload.put('assignment_group', routingOutcome.assignmentTarget.externalAssignmentId);
            }
            payload.put('u_salesforce_case_id', caseRecord.Id);

            SN_ServiceNowClient.IncidentCreateRequest request = new SN_ServiceNowClient.IncidentCreateRequest();
            request.orgKey = orgKey;
            request.correlationId = correlationId;
            request.idempotencyKey = idempotencyKey;
            request.payload = payload;

            SN_ServiceNowClient.ResponseEnvelope response = serviceNowGateway.createIncident(request);
            if (response.success == true) {
                String targetRecordId = extractTargetRecordId(response.responseBody);
                SN_TransactionLogService.markSuccess(reservation.transactionId, targetRecordId, response.safeSummary);
                result.targetRecordId = targetRecordId;
                result.status = 'Succeeded';
                return result;
            }

            SN_TransactionLogService.markFailure(
                reservation.transactionId,
                String.valueOf(response.failureCategory),
                response.failureCode,
                'ServiceNow create incident request failed.',
                response.retryable,
                response.safeSummary
            );
            result.status = response.retryable == true ? 'Retrying' : 'Failed';
            throw new OrchestrationException('ServiceNow request failed with status ' + response.statusCode + '.');
        } catch (Exception ex) {
            if (!(ex instanceof OrchestrationException)) {
                SN_TransactionLogService.markFailure(
                    reservation.transactionId,
                    'UNHANDLED',
                    'UNHANDLED_EXCEPTION',
                    ex.getMessage(),
                    false,
                    'orchestrationException'
                );
            }
            throw ex;
        }
    }

    @TestVisible
    static void resetDependencies() {
        caseRepository = new DefaultCaseRepository();
        featureToggleGateway = new DefaultFeatureToggleGateway();
        configurationGateway = new DefaultConfigurationGateway();
        fieldMappingGateway = new DefaultFieldMappingGateway();
        routingGateway = new DefaultRoutingGateway();
        serviceNowGateway = new DefaultServiceNowGateway();
    }

    private static String resolveOrgKey(RequestContext context) {
        if (!String.isBlank(context.orgKey)) {
            return context.orgKey;
        }
        return 'DEFAULT';
    }

    private static String buildBusinessContext(String orgKey, String requestTypeKey, String businessContext) {
        return String.join(new List<String>{ orgKey, requestTypeKey, businessContext }, '|');
    }

    private static String extractTargetRecordId(String responseBody) {
        if (String.isBlank(responseBody)) {
            return null;
        }
        Object parsed = JSON.deserializeUntyped(responseBody);
        if (!(parsed instanceof Map<String, Object>)) {
            return null;
        }
        Map<String, Object> root = (Map<String, Object>) parsed;
        if (root.containsKey('result') && root.get('result') instanceof Map<String, Object>) {
            Map<String, Object> result = (Map<String, Object>) root.get('result');
            if (result.containsKey('sys_id')) {
                return String.valueOf(result.get('sys_id'));
            }
            if (result.containsKey('number')) {
                return String.valueOf(result.get('number'));
            }
        }
        return null;
    }

    private class DefaultCaseRepository implements ICaseRepository {
        public Case load(Id caseId) {
            List<Case> records = [
                SELECT Id, Subject, Description, Origin, Priority, Type
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
            return records.isEmpty() ? null : records[0];
        }
    }

    private class DefaultFeatureToggleGateway implements IFeatureToggleGateway {
        public Boolean isEnabled(String featureKey, String orgKey) {
            return SN_FeatureToggleService.isEnabled(featureKey, orgKey);
        }
    }

    private class DefaultConfigurationGateway implements IConfigurationGateway {
        public SN_ConfigService.OrgConfig getOrgConfig(String orgKey) {
            return SN_ConfigService.getOrgConfigWrapper(orgKey);
        }
        public SN_ConfigService.RequestTypeConfig getRequestType(String orgKey, String requestTypeKey) {
            return SN_ConfigService.getRequestTypeConfigWrapper(orgKey, requestTypeKey);
        }
    }

    private class DefaultFieldMappingGateway implements IFieldMappingGateway {
        public Map<String, Object> buildPayload(String orgKey, String requestTypeKey, Case caseRecord, Map<String, Object> relatedData) {
            return SN_FieldMappingService.buildIncidentPayload(orgKey, requestTypeKey, caseRecord, relatedData).fields;
        }
    }

    private class DefaultRoutingGateway implements IRoutingGateway {
        public SN_RoutingService.RoutingOutcome resolve(SN_RoutingService.RoutingContext context) {
            return SN_RoutingService.resolve(context);
        }
    }

    private class DefaultServiceNowGateway implements IServiceNowGateway {
        public SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request) {
            return SN_ServiceNowClient.createIncidentWithHandling(request);
        }
    }

    public class OrchestrationException extends Exception {}
}
