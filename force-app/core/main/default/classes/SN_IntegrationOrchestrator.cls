public with sharing class SN_IntegrationOrchestrator {
    public class RequestContext {
        public String orgKey;
        public String requestTypeKey;
        public String businessContext;
        public String featureKey;
        public String operationName;
        public String sourceObjectApiName;

        public RequestContext() {
            operationName = 'createIncident';
            featureKey = 'CASE_TO_INCIDENT_SYNC';
            sourceObjectApiName = 'Case';
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

    private class ExecutionReservation {
        public Id transactionId;
        public String idempotencyKey;
        public Boolean retryExecution;
        public String status;
        public String targetRecordId;
        public Boolean shouldProcess;
    }

    public interface ICaseRepository { Case load(Id caseId); }
    public interface IFeatureToggleGateway { Boolean isEnabled(String featureKey, String orgKey); Boolean isEnabled(String featureKey, String orgKey, String requestTypeKey); }
    public interface IConfigurationGateway {
        SN_ConfigService.OrgConfig getOrgConfig(String orgKey);
        SN_ConfigService.RequestTypeConfig getRequestType(String orgKey, String requestTypeKey);
    }
    public interface IFieldMappingGateway { Map<String, Object> buildPayload(String orgKey, String requestTypeKey, Case caseRecord, Map<String, Object> relatedData); }
    public interface IRoutingGateway { SN_RoutingService.RoutingOutcome resolve(SN_RoutingService.RoutingContext context); }
    public interface IServiceNowGateway { SN_ServiceNowClient.ResponseEnvelope createIncident(SN_ServiceNowClient.IncidentCreateRequest request); }
    public interface ITransactionLogger {
        void markInProgress(Id transactionId, String stageName);
        void markSuccess(Id transactionId, String targetRecordId, String safeSummary);
        void markFailure(Id transactionId, String category, String failureClass, String errorCode, String errorMessage, Boolean retryable, String safeSummary);
    }
    public interface IPayloadValidator {
        SN_PayloadValidationService.ValidationResult validateIncidentCreate(String orgKey, String requestTypeKey, Map<String, Object> payload);
    }

    @TestVisible private static ICaseRepository caseRepository = new DefaultCaseRepository();
    @TestVisible private static IFeatureToggleGateway featureToggleGateway = new DefaultFeatureToggleGateway();
    @TestVisible private static IConfigurationGateway configurationGateway = new DefaultConfigurationGateway();
    @TestVisible private static IFieldMappingGateway fieldMappingGateway = new DefaultFieldMappingGateway();
    @TestVisible private static IRoutingGateway routingGateway = new DefaultRoutingGateway();
    @TestVisible private static IServiceNowGateway serviceNowGateway = new DefaultServiceNowGateway();
    @TestVisible private static ITransactionLogger transactionLogger = new DefaultTransactionLogger();
    @TestVisible private static IPayloadValidator payloadValidator = new DefaultPayloadValidator();

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
        ensureFeatureEnabled(effectiveContext, orgKey);

        SN_ConfigService.RequestTypeConfig requestType = validateConfiguration(orgKey, effectiveContext.requestTypeKey);
        SN_ConfigService.OrgConfig orgConfig = configurationGateway.getOrgConfig(orgKey);
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
        seedTransactionReportingContext(reservation.transactionId, orgConfig, effectiveContext.sourceObjectApiName, caseRecord);

        ExecutionReservation execution = new ExecutionReservation();
        execution.transactionId = reservation.transactionId;
        execution.idempotencyKey = idempotencyKey;
        execution.retryExecution = reservation.retryExecution;
        execution.status = reservation.status;
        execution.targetRecordId = reservation.targetRecordId;
        execution.shouldProcess = reservation.shouldProcess;
        return executeIncident(caseRecord, effectiveContext, requestType, orgConfig, correlationId, execution);
    }

    public static OrchestrationResult retryExistingTransaction(Id transactionId) {
        if (transactionId == null) {
            throw new OrchestrationException('Transaction Id is required.');
        }
        Integration_Transaction__c transactionRecord = [
            SELECT Id, IdempotencyKey__c, SourceRecordId__c, SalesforceOrgCode__c, RequestType__c,
                Status__c, RetryCount__c, TargetRecordId__c
            FROM Integration_Transaction__c
            WHERE Id = :transactionId
            LIMIT 1
        ];
        if (transactionRecord.Status__c == 'Succeeded') {
            OrchestrationResult skipped = new OrchestrationResult();
            skipped.transactionId = transactionRecord.Id;
            skipped.idempotencyKey = transactionRecord.IdempotencyKey__c;
            skipped.status = transactionRecord.Status__c;
            skipped.targetRecordId = transactionRecord.TargetRecordId__c;
            skipped.skippedDuplicate = true;
            return skipped;
        }

        Id caseId = String.isBlank(transactionRecord.SourceRecordId__c) ? null : Id.valueOf(transactionRecord.SourceRecordId__c);
        Case caseRecord = caseRepository.load(caseId);
        if (caseRecord == null) {
            throw new OrchestrationException('Source Case not found for transaction ' + transactionId + '.');
        }

        RequestContext context = new RequestContext();
        context.orgKey = transactionRecord.SalesforceOrgCode__c;
        context.requestTypeKey = transactionRecord.RequestType__c;
        ensureFeatureEnabled(context, context.orgKey);
        SN_ConfigService.OrgConfig orgConfig = configurationGateway.getOrgConfig(context.orgKey);
        SN_ConfigService.RequestTypeConfig requestType = validateConfiguration(context.orgKey, context.requestTypeKey);

        Integer retryCount = transactionRecord.RetryCount__c == null ? 0 : Integer.valueOf(transactionRecord.RetryCount__c);
        update new Integration_Transaction__c(
            Id = transactionRecord.Id,
            Status__c = 'Retrying',
            RetryCount__c = retryCount + 1,
            StartedAt__c = System.now(),
            CompletedAt__c = null,
            ErrorCategory__c = null,
            ErrorCode__c = null,
            ErrorSummary__c = null
        );

        ExecutionReservation execution = new ExecutionReservation();
        execution.transactionId = transactionRecord.Id;
        execution.idempotencyKey = transactionRecord.IdempotencyKey__c;
        execution.retryExecution = true;
        execution.status = 'Retrying';
        execution.targetRecordId = transactionRecord.TargetRecordId__c;
        execution.shouldProcess = true;
        seedTransactionReportingContext(transactionRecord.Id, orgConfig, context.sourceObjectApiName, caseRecord);
        return executeIncident(caseRecord, context, requestType, orgConfig, SN_ServiceNowClient.generateCorrelationId(), execution);
    }

    @TestVisible
    static void resetDependencies() {
        caseRepository = new DefaultCaseRepository();
        featureToggleGateway = new DefaultFeatureToggleGateway();
        configurationGateway = new DefaultConfigurationGateway();
        fieldMappingGateway = new DefaultFieldMappingGateway();
        routingGateway = new DefaultRoutingGateway();
        serviceNowGateway = new DefaultServiceNowGateway();
        transactionLogger = new DefaultTransactionLogger();
        payloadValidator = new DefaultPayloadValidator();
    }

    private static OrchestrationResult executeIncident(Case caseRecord, RequestContext context,
        SN_ConfigService.RequestTypeConfig requestType, SN_ConfigService.OrgConfig orgConfig, String correlationId, ExecutionReservation reservation) {
        OrchestrationResult result = new OrchestrationResult();
        result.transactionId = reservation.transactionId;
        result.idempotencyKey = reservation.idempotencyKey;
        result.retryExecution = reservation.retryExecution;
        result.status = reservation.status;
        result.targetRecordId = reservation.targetRecordId;
        if (!reservation.shouldProcess) {
            result.skippedDuplicate = true;
            return result;
        }

        transactionLogger.markInProgress(reservation.transactionId, 'Routing');

        try {
            SN_RoutingService.RoutingContext routingContext = new SN_RoutingService.RoutingContext();
            routingContext.orgKey = context.orgKey;
            routingContext.requestTypeKey = requestType.requestTypeKey;
            routingContext.metadata.put('origin', caseRecord.Origin);
            routingContext.metadata.put('priority', caseRecord.Priority);

            SN_RoutingService.RoutingOutcome routingOutcome = routingGateway.resolve(routingContext);
            Map<String, Object> payload = fieldMappingGateway.buildPayload(context.orgKey, requestType.requestTypeKey, caseRecord, null);
            if (routingOutcome != null && routingOutcome.assignmentTarget != null) {
                payload.put('assignment_group', routingOutcome.assignmentTarget.externalAssignmentId);
            }
            payload.put('u_salesforce_case_id', caseRecord.Id);
            SN_PayloadValidationService.ValidationResult validationResult = payloadValidator.validateIncidentCreate(
                context.orgKey,
                requestType.requestTypeKey,
                payload
            );
            if (validationResult.valid != true) {
                transactionLogger.markFailure(
                    reservation.transactionId,
                    'Validation',
                    'PreTransportValidation',
                    validationResult.code,
                    validationResult.message,
                    false,
                    validationResult.safeSummary
                );
                throw new OrchestrationException(validationResult.message);
            }

            SN_ServiceNowClient.IncidentCreateRequest request = new SN_ServiceNowClient.IncidentCreateRequest();
            request.orgKey = context.orgKey;
            request.correlationId = correlationId;
            request.idempotencyKey = reservation.idempotencyKey;
            request.payload = payload;

            SN_ServiceNowClient.ResponseEnvelope response = serviceNowGateway.createIncident(request);
            if (response.success == true) {
                Map<String, String> incidentReference = extractIncidentReference(response.responseBody);
                String targetRecordId = incidentReference.get('sys_id');
                transactionLogger.markSuccess(reservation.transactionId, targetRecordId, response.safeSummary);
                SN_IncidentLinkService.upsertLink(
                    SN_IncidentLinkService.buildCaseIncidentContext(
                        reservation.transactionId,
                        caseRecord,
                        context.orgKey,
                        orgConfig == null ? null : orgConfig.businessUnit,
                        incidentReference.get('sys_id'),
                        incidentReference.get('number'),
                        'Active'
                    )
                );
                result.targetRecordId = targetRecordId;
                result.status = 'Succeeded';
                return result;
            }

            transactionLogger.markFailure(
                reservation.transactionId,
                mapFailureCategory(response.failureCategory),
                response.failureCategory == null ? 'Unknown' : String.valueOf(response.failureCategory),
                response.failureCode,
                'ServiceNow create incident request failed.',
                response.retryable,
                response.safeSummary
            );
            SN_IncidentLinkService.upsertLink(
                SN_IncidentLinkService.buildCaseIncidentContext(
                    reservation.transactionId,
                    caseRecord,
                    context.orgKey,
                    orgConfig == null ? null : orgConfig.businessUnit,
                    null,
                    null,
                    'Failed'
                )
            );
            result.status = response.retryable == true ? 'Retrying' : 'Failed';
            throw new OrchestrationException('ServiceNow request failed with status ' + response.statusCode + '.');
        } catch (Exception ex) {
            if (ex instanceof SN_ExceptionTaxonomy.IntegrationException) {
                SN_ExceptionTaxonomy.IntegrationException typed = (SN_ExceptionTaxonomy.IntegrationException) ex;
                transactionLogger.markFailure(
                    reservation.transactionId,
                    SN_ExceptionTaxonomy.toErrorCategory(typed.category),
                    SN_ExceptionTaxonomy.toFailureClass(typed.category),
                    typed.code,
                    typed.getMessage(),
                    typed.retryable,
                    'orchestrationException'
                );
            } else if (!(ex instanceof OrchestrationException)) {
                transactionLogger.markFailure(
                    reservation.transactionId,
                    'Unknown',
                    'Unknown',
                    'UNHANDLED_EXCEPTION',
                    ex.getMessage(),
                    false,
                    'orchestrationException'
                );
            }
            throw ex;
        }
    }

    private static void ensureFeatureEnabled(RequestContext context, String orgKey) {
        if (!featureToggleGateway.isEnabled(context.featureKey, orgKey, context.requestTypeKey)) {
            throw new SN_ExceptionTaxonomy.ConfigurationException('FEATURE_DISABLED', 'Feature ' + context.featureKey + ' is disabled for org ' + orgKey + ' and request type ' + context.requestTypeKey + '.');
        }
    }

    private static SN_ConfigService.RequestTypeConfig validateConfiguration(String orgKey, String requestTypeKey) {
        SN_ConfigService.OrgConfig orgConfig = configurationGateway.getOrgConfig(orgKey);
        if (orgConfig == null) { throw new SN_ExceptionTaxonomy.ConfigurationException('ORG_CONFIG_MISSING', 'No active org config found for org ' + orgKey + '.'); }
        if (SN_ConfigService.getEndpointConfig(orgConfig.endpointConfigKey) == null) { throw new SN_ExceptionTaxonomy.ConfigurationException('ENDPOINT_CONFIG_MISSING', 'No active endpoint config found for org ' + orgKey + '.'); }
        SN_ConfigService.RequestTypeConfig requestType = configurationGateway.getRequestType(orgKey, requestTypeKey);
        if (requestType == null) { throw new SN_ExceptionTaxonomy.ConfigurationException('REQUEST_TYPE_MISSING', 'No active request type found for org ' + orgKey + '.'); }
        if (SN_ConfigService.getIncidentTemplate(orgKey, requestType.incidentTemplateKey) == null) { throw new SN_ExceptionTaxonomy.ConfigurationException('INCIDENT_TEMPLATE_MISSING', 'No active incident template found for org ' + orgKey + ' and request type ' + requestType.requestTypeKey + '.'); }
        return requestType;
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

    private static Map<String, String> extractIncidentReference(String responseBody) {
        Map<String, String> incidentReference = new Map<String, String>();
        if (String.isBlank(responseBody)) {
            return incidentReference;
        }
        Object parsed = JSON.deserializeUntyped(responseBody);
        if (!(parsed instanceof Map<String, Object>)) {
            return incidentReference;
        }
        Map<String, Object> root = (Map<String, Object>) parsed;
        if (root.containsKey('result') && root.get('result') instanceof Map<String, Object>) {
            Map<String, Object> innerResult = (Map<String, Object>) root.get('result');
            if (innerResult.containsKey('sys_id')) {
                incidentReference.put('sys_id', String.valueOf(innerResult.get('sys_id')));
            }
            if (innerResult.containsKey('number')) {
                incidentReference.put('number', String.valueOf(innerResult.get('number')));
            }
        }
        return incidentReference;
    }

    private static void seedTransactionReportingContext(Id transactionId, SN_ConfigService.OrgConfig orgConfig, String sourceObjectApiName, Case caseRecord) {
        if (transactionId == null) {
            return;
        }
        update new Integration_Transaction__c(
            Id = transactionId,
            BusinessUnit__c = orgConfig == null ? null : orgConfig.businessUnit,
            SourceObjectApiName__c = sourceObjectApiName,
            SourceRecordLabel__c = caseRecord == null ? null : caseRecord.CaseNumber
        );
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
        if (failureCategory == SN_ServiceNowClient.FailureCategory.PRE_TRANSPORT_VALIDATION) {
            return 'Validation';
        }
        return 'Unknown';
    }

    private class DefaultCaseRepository implements ICaseRepository {
        public Case load(Id caseId) {
            List<Case> records = [
                SELECT Id, CaseNumber, Subject, Description, Origin, Priority, Type
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
            return records.isEmpty() ? null : records[0];
        }
    }

    private class DefaultFeatureToggleGateway implements IFeatureToggleGateway {
        public Boolean isEnabled(String featureKey, String orgKey) { return SN_FeatureToggleService.isEnabled(featureKey, orgKey); }
        public Boolean isEnabled(String featureKey, String orgKey, String requestTypeKey) { return SN_FeatureToggleService.isEnabled(featureKey, orgKey, requestTypeKey); }
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

    private class DefaultTransactionLogger implements ITransactionLogger {
        public void markInProgress(Id transactionId, String stageName) {
            SN_TransactionLogService.markInProgress(transactionId, stageName);
        }
        public void markSuccess(Id transactionId, String targetRecordId, String safeSummary) {
            SN_TransactionLogService.markSuccess(transactionId, targetRecordId, safeSummary);
        }
        public void markFailure(Id transactionId, String category, String failureClass, String errorCode, String errorMessage, Boolean retryable, String safeSummary) {
            SN_TransactionLogService.markFailure(transactionId, category, failureClass, errorCode, errorMessage, retryable, safeSummary);
        }
    }

    private class DefaultPayloadValidator implements IPayloadValidator {
        public SN_PayloadValidationService.ValidationResult validateIncidentCreate(String orgKey, String requestTypeKey, Map<String, Object> payload) {
            return SN_PayloadValidationService.validateIncidentCreate(orgKey, requestTypeKey, payload);
        }
    }

    public class OrchestrationException extends Exception {}
}
