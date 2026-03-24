public with sharing class SN_ServiceNowClient {
    @TestVisible private static List<SN_Endpoint_Config__mdt> endpointConfigOverrides;

    public enum FailureCategory { FUNCTIONAL, TECHNICAL, AUTH, CONFIGURATION, PRE_TRANSPORT_VALIDATION }

    public class RequestEnvelope {
        public String methodName;
        public String relativePath;
        public String orgKey;
        public String correlationId;
        public String operationName;
        public String idempotencyKey;
        public String body;
        public Integer timeoutMs;
    }

    public class ResponseEnvelope {
        public Integer statusCode;
        public String responseBody;
        public String correlationId;
        public String requestId;
        public String safeSummary;
        public Boolean success;
        public Boolean retryable;
        public FailureCategory failureCategory;
        public String failureCode;
    }

    public class IncidentCreateRequest { public Map<String, Object> payload; public String orgKey; public String correlationId; public String idempotencyKey; }
    public class IncidentUpdateRequest { public String incidentSysId; public Map<String, Object> payload; public String orgKey; public String correlationId; public String idempotencyKey; }
    public class CommentRequest { public String incidentSysId; public String comment; public String orgKey; public String correlationId; public String idempotencyKey; }
    public class FileSyncRequest { public String incidentSysId; public String fileName; public String contentType; public String base64Body; public String orgKey; public String correlationId; public String idempotencyKey; }

    public class ServiceNowClientException extends Exception {
        public FailureCategory failureCategory;
        public Integer statusCode;
        public String correlationId;
        public Boolean retryable;
        public String errorCode;
    }

    public interface IEndpointConfigResolver { EndpointConfig resolve(String orgKey); }
    public interface IHttpTransport { HttpResponse send(HttpRequest request); }
    public interface IClientLogger { void onRequest(String operationName, String correlationId, String safeSummary); void onResponse(String operationName, String correlationId, String safeSummary); }

    @TestVisible private static IEndpointConfigResolver endpointConfigResolver = new DefaultEndpointConfigResolver();
    @TestVisible private static IHttpTransport httpTransport = new DefaultHttpTransport();
    @TestVisible private static IClientLogger clientLogger = new NullClientLogger();

    /** Sends an incident create request to ServiceNow using the configured Named Credential and endpoint metadata. */
    public static HttpResponse createIncident(Map<String, Object> payload, String orgKey) {
        IncidentCreateRequest request = new IncidentCreateRequest();
        request.payload = payload;
        request.orgKey = orgKey;
        request.correlationId = generateCorrelationId();
        return createIncident(request);
    }

    public static HttpResponse createIncident(IncidentCreateRequest request) {
        RequestEnvelope envelope = buildEnvelope('POST', '/incident', request == null ? null : request.orgKey,
            request == null ? null : request.correlationId, request == null ? null : request.idempotencyKey,
            'createIncident', request == null ? null : JSON.serialize(request.payload));
        return sendInternal(envelope).response;
    }

    public static ResponseEnvelope createIncidentWithHandling(IncidentCreateRequest request) {
        RequestEnvelope envelope = buildEnvelope('POST', '/incident', request == null ? null : request.orgKey,
            request == null ? null : request.correlationId, request == null ? null : request.idempotencyKey,
            'createIncident', request == null ? null : JSON.serialize(request.payload));
        return sendInternal(envelope);
    }

    public static ResponseEnvelope updateIncident(IncidentUpdateRequest request) {
        RequestEnvelope envelope = buildEnvelope('PATCH', '/incident/' + EncodingUtil.urlEncode(request.incidentSysId, 'UTF-8'),
            request.orgKey, request.correlationId, request.idempotencyKey, 'updateIncident', JSON.serialize(request.payload));
        return sendInternal(envelope);
    }

    public static ResponseEnvelope addComment(CommentRequest request) {
        Map<String, Object> body = new Map<String, Object>{ 'comments' => request.comment };
        RequestEnvelope envelope = buildEnvelope('PATCH', '/incident/' + EncodingUtil.urlEncode(request.incidentSysId, 'UTF-8'),
            request.orgKey, request.correlationId, request.idempotencyKey, 'addComment', JSON.serialize(body));
        return sendInternal(envelope);
    }

    public static ResponseEnvelope synchronizeFile(FileSyncRequest request) {
        Map<String, Object> body = new Map<String, Object>{
            'file_name' => request.fileName,
            'content_type' => request.contentType,
            'table_name' => 'incident',
            'table_sys_id' => request.incidentSysId,
            'uploadFile' => request.base64Body
        };
        RequestEnvelope envelope = buildEnvelope('POST', '/attachment/file', request.orgKey, request.correlationId,
            request.idempotencyKey, 'syncFile', JSON.serialize(body));
        return sendInternal(envelope);
    }

    /** Sends a generic request to ServiceNow for future reuse across integration operations. */
    public static HttpResponse send(String methodName, String relativePath, String body, String orgKey) {
        RequestEnvelope envelope = buildEnvelope(methodName, relativePath, orgKey, generateCorrelationId(), null, 'genericSend', body);
        return sendInternal(envelope).response;
    }

    @TestVisible
    static void resetDependencies() {
        endpointConfigResolver = new DefaultEndpointConfigResolver();
        httpTransport = new DefaultHttpTransport();
        clientLogger = new NullClientLogger();
    }

    @TestVisible
    private class SendResult extends ResponseEnvelope {
        public HttpResponse response;
    }

    @TestVisible
    private static SendResult sendInternal(RequestEnvelope envelope) {
        validateEnvelope(envelope);

        SendResult result = new SendResult();
        result.correlationId = String.isBlank(envelope.correlationId) ? generateCorrelationId() : envelope.correlationId;

        EndpointConfig endpoint = endpointConfigResolver.resolve(envelope.orgKey);
        if (endpoint == null || String.isBlank(endpoint.namedCredential)) {
            throw buildException(FailureCategory.CONFIGURATION, null, result.correlationId, false, 'MISSING_ENDPOINT_CONFIG',
                'No active ServiceNow endpoint configuration is available for org ' + envelope.orgKey + '.');
        }

        HttpRequest request = buildHttpRequest(endpoint, envelope, result.correlationId);
        clientLogger.onRequest(envelope.operationName, result.correlationId, 'operation=' + envelope.operationName + ';path=' + envelope.relativePath);

        try {
            result.response = httpTransport.send(request);
            result.statusCode = result.response.getStatusCode();
            result.responseBody = result.response.getBody();
            result.requestId = result.response.getHeader('X-Transaction-Id');
            result.safeSummary = buildSafeSummary(envelope.operationName, result.statusCode, result.correlationId, result.requestId);
            applyStatusClassification(result, result.statusCode);
            clientLogger.onResponse(envelope.operationName, result.correlationId, result.safeSummary);
            return result;
        } catch (CalloutException ex) {
            Boolean timeoutLike = isTimeoutError(ex);
            throw buildException(FailureCategory.TECHNICAL, null, result.correlationId, timeoutLike, timeoutLike ? 'CALLOUT_TIMEOUT' : 'CALLOUT_EXCEPTION', ex.getMessage());
        }
    }

    private static void validateEnvelope(RequestEnvelope envelope) {
        if (envelope == null) {
            throw buildException(FailureCategory.PRE_TRANSPORT_VALIDATION, null, generateCorrelationId(), false,
                'REQUEST_REQUIRED', 'ServiceNow request envelope is required.');
        }
        if (String.isBlank(envelope.orgKey)) {
            throw buildException(FailureCategory.PRE_TRANSPORT_VALIDATION, null, generateCorrelationId(), false,
                'ORG_KEY_REQUIRED', 'Org key is required before ServiceNow transport.');
        }
        if (String.isBlank(envelope.methodName) || String.isBlank(envelope.relativePath)) {
            throw buildException(FailureCategory.PRE_TRANSPORT_VALIDATION, null, generateCorrelationId(), false,
                'HTTP_SHAPE_INVALID', 'HTTP method and relative path are required before ServiceNow transport.');
        }
    }

    private static HttpRequest buildHttpRequest(EndpointConfig endpoint, RequestEnvelope envelope, String correlationId) {
        HttpRequest request = new HttpRequest();
        request.setMethod(envelope.methodName.toUpperCase());
        request.setEndpoint('callout:' + endpoint.namedCredential + normalizePath(endpoint.basePath, envelope.relativePath));
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('X-Correlation-Id', correlationId);
        request.setHeader('X-Salesforce-Source', 'Salesforce');
        if (!String.isBlank(envelope.idempotencyKey)) {
            request.setHeader('Idempotency-Key', envelope.idempotencyKey);
        }
        request.setTimeout(envelope.timeoutMs == null ? endpoint.timeoutMs : envelope.timeoutMs);
        if (!String.isBlank(envelope.body)) {
            request.setBody(envelope.body);
        }
        return request;
    }

    private static void applyStatusClassification(ResponseEnvelope result, Integer statusCode) {
        result.success = statusCode != null && statusCode >= 200 && statusCode < 300;
        result.retryable = false;
        if (result.success) {
            return;
        }
        if (statusCode == 401 || statusCode == 403) {
            result.failureCategory = FailureCategory.AUTH;
            result.failureCode = 'AUTH_FAILURE';
        } else if (statusCode == 400 || statusCode == 404 || statusCode == 409 || statusCode == 422) {
            result.failureCategory = FailureCategory.FUNCTIONAL;
            result.failureCode = 'FUNCTIONAL_FAILURE';
        } else if (statusCode == 408 || statusCode == 429 || statusCode == 500 || statusCode == 502 || statusCode == 503 || statusCode == 504) {
            result.failureCategory = FailureCategory.TECHNICAL;
            result.failureCode = 'RETRYABLE_HTTP_FAILURE';
            result.retryable = true;
        } else {
            result.failureCategory = FailureCategory.TECHNICAL;
            result.failureCode = 'HTTP_FAILURE';
        }
    }

    private static ServiceNowClientException buildException(FailureCategory category, Integer statusCode,
        String correlationId, Boolean retryable, String errorCode, String messageText) {
        ServiceNowClientException ex = new ServiceNowClientException(messageText);
        ex.failureCategory = category;
        ex.statusCode = statusCode;
        ex.correlationId = correlationId;
        ex.retryable = retryable;
        ex.errorCode = errorCode;
        return ex;
    }

    private static String buildSafeSummary(String operationName, Integer statusCode, String correlationId, String requestId) {
        List<String> parts = new List<String>{
            'operation=' + operationName,
            'statusCode=' + String.valueOf(statusCode),
            'correlationId=' + correlationId
        };
        if (!String.isBlank(requestId)) {
            parts.add('servicenowRequestId=' + requestId);
        }
        return String.join(parts, ';');
    }

    private static String normalizePath(String basePath, String relativePath) {
        String left = String.isBlank(basePath) ? '' : basePath.trim();
        String right = String.isBlank(relativePath) ? '' : relativePath.trim();
        if (!left.startsWith('/')) {
            left = '/' + left;
        }
        if (left.endsWith('/')) {
            left = left.substring(0, left.length() - 1);
        }
        if (!right.startsWith('/')) {
            right = '/' + right;
        }
        return left + right;
    }

    private static Boolean isTimeoutError(CalloutException ex) {
        String messageText = ex == null ? null : ex.getMessage();
        if (String.isBlank(messageText)) {
            return false;
        }
        String lowered = messageText.toLowerCase();
        return lowered.contains('timeout') || lowered.contains('read timed out');
    }

    private class EndpointConfig {
        public String key;
        public String namedCredential;
        public String basePath;
        public Integer timeoutMs;
    }

    private class DefaultEndpointConfigResolver implements IEndpointConfigResolver {
        public EndpointConfig resolve(String orgKey) {
            SN_ConfigService.OrgConfig orgConfig = SN_ConfigService.getOrgConfigWrapper(orgKey);
            if (orgConfig == null || String.isBlank(orgConfig.endpointConfigKey)) {
                return null;
            }
            for (SN_Endpoint_Config__mdt record : getEndpointConfigRecords()) {
                if (record.Is_Active__c == true && record.Endpoint_Config_Key__c == orgConfig.endpointConfigKey) {
                    EndpointConfig config = new EndpointConfig();
                    config.key = record.Endpoint_Config_Key__c;
                    config.namedCredential = record.Named_Credential__c;
                    config.basePath = record.Base_Path__c;
                    config.timeoutMs = record.Timeout_Ms__c == null ? 10000 : Integer.valueOf(record.Timeout_Ms__c);
                    return config;
                }
            }
            return null;
        }
    }

    private class DefaultHttpTransport implements IHttpTransport {
        public HttpResponse send(HttpRequest request) {
            return new Http().send(request);
        }
    }

    private class NullClientLogger implements IClientLogger {
        public void onRequest(String operationName, String correlationId, String safeSummary) {}
        public void onResponse(String operationName, String correlationId, String safeSummary) {}
    }

    @TestVisible
    static void setEndpointConfigTestData(List<SN_Endpoint_Config__mdt> endpointConfigs) {
        endpointConfigOverrides = endpointConfigs;
    }

    @TestVisible
    static void clearEndpointConfigTestData() {
        endpointConfigOverrides = null;
    }

    @TestVisible
    private static RequestEnvelope buildEnvelope(String methodName, String relativePath, String orgKey,
        String correlationId, String idempotencyKey, String operationName, String body) {
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = methodName;
        envelope.relativePath = relativePath;
        envelope.orgKey = orgKey;
        envelope.correlationId = correlationId;
        envelope.idempotencyKey = idempotencyKey;
        envelope.operationName = operationName;
        envelope.body = body;
        return envelope;
    }

    private static List<SN_Endpoint_Config__mdt> getEndpointConfigRecords() {
        if (Test.isRunningTest() && endpointConfigOverrides != null) {
            return endpointConfigOverrides;
        }
        return [
            SELECT DeveloperName, Endpoint_Config_Key__c, Named_Credential__c, Base_Path__c, Timeout_Ms__c, Is_Active__c
            FROM SN_Endpoint_Config__mdt
        ];
    }

    @TestVisible
    static String generateCorrelationId() {
        return 'SNOW-' + String.valueOf(Crypto.getRandomLong()).replace('-', '');
    }
}
