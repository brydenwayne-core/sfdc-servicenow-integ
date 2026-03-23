public with sharing class SN_ServiceNowClient {
    @TestVisible private static List<SN_Endpoint_Config__mdt> endpointConfigOverrides;

    public enum FailureCategory { FUNCTIONAL, TECHNICAL, AUTH, CONFIGURATION }

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

    /** Sends an incident create request to ServiceNow using the configured Named Credential and endpoint metadata. */
    public static HttpResponse createIncident(Map<String, Object> payload, String orgKey) {
        IncidentCreateRequest request = new IncidentCreateRequest();
        request.payload = payload;
        request.orgKey = orgKey;
        request.correlationId = generateCorrelationId();
        return createIncident(request);
    }

    public static HttpResponse createIncident(IncidentCreateRequest request) {
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = 'POST';
        envelope.relativePath = '/incident';
        envelope.orgKey = request.orgKey;
        envelope.correlationId = request.correlationId;
        envelope.idempotencyKey = request.idempotencyKey;
        envelope.operationName = 'createIncident';
        envelope.body = JSON.serialize(request.payload);
        return sendInternal(envelope).response;
    }

    public static ResponseEnvelope createIncidentWithHandling(IncidentCreateRequest request) {
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = 'POST';
        envelope.relativePath = '/incident';
        envelope.orgKey = request.orgKey;
        envelope.correlationId = request.correlationId;
        envelope.idempotencyKey = request.idempotencyKey;
        envelope.operationName = 'createIncident';
        envelope.body = JSON.serialize(request.payload);
        return sendInternal(envelope);
    }

    public static ResponseEnvelope updateIncident(IncidentUpdateRequest request) {
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = 'PATCH';
        envelope.relativePath = '/incident/' + EncodingUtil.urlEncode(request.incidentSysId, 'UTF-8');
        envelope.orgKey = request.orgKey;
        envelope.correlationId = request.correlationId;
        envelope.idempotencyKey = request.idempotencyKey;
        envelope.operationName = 'updateIncident';
        envelope.body = JSON.serialize(request.payload);
        return sendInternal(envelope);
    }

    public static ResponseEnvelope addComment(CommentRequest request) {
        Map<String, Object> body = new Map<String, Object>{ 'comments' => request.comment };
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = 'PATCH';
        envelope.relativePath = '/incident/' + EncodingUtil.urlEncode(request.incidentSysId, 'UTF-8');
        envelope.orgKey = request.orgKey;
        envelope.correlationId = request.correlationId;
        envelope.idempotencyKey = request.idempotencyKey;
        envelope.operationName = 'addComment';
        envelope.body = JSON.serialize(body);
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
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = 'POST';
        envelope.relativePath = '/attachment/file';
        envelope.orgKey = request.orgKey;
        envelope.correlationId = request.correlationId;
        envelope.idempotencyKey = request.idempotencyKey;
        envelope.operationName = 'syncFile';
        envelope.body = JSON.serialize(body);
        return sendInternal(envelope);
    }

    /** Sends a generic request to ServiceNow for future reuse across integration operations. */
    public static HttpResponse send(String methodName, String relativePath, String body, String orgKey) {
        RequestEnvelope envelope = new RequestEnvelope();
        envelope.methodName = methodName;
        envelope.relativePath = relativePath;
        envelope.body = body;
        envelope.orgKey = orgKey;
        envelope.correlationId = generateCorrelationId();
        envelope.operationName = 'genericSend';
        return sendInternal(envelope).response;
    }

    @TestVisible
    private class SendResult extends ResponseEnvelope {
        public HttpResponse response;
    }

    @TestVisible
    private static SendResult sendInternal(RequestEnvelope envelope) {
        SendResult result = new SendResult();
        result.correlationId = String.isBlank(envelope.correlationId) ? generateCorrelationId() : envelope.correlationId;

        EndpointConfig endpoint = getEndpointConfig(envelope.orgKey);
        if (endpoint == null || String.isBlank(endpoint.namedCredential)) {
            throw buildException(FailureCategory.CONFIGURATION, null, result.correlationId, false, 'MISSING_ENDPOINT_CONFIG',
                'No active ServiceNow endpoint configuration is available for org ' + envelope.orgKey + '.');
        }

        HttpRequest request = new HttpRequest();
        request.setMethod(envelope.methodName);
        request.setEndpoint('callout:' + endpoint.namedCredential + normalizePath(endpoint.basePath, envelope.relativePath));
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('X-Correlation-Id', result.correlationId);
        if (!String.isBlank(envelope.idempotencyKey)) {
            request.setHeader('Idempotency-Key', envelope.idempotencyKey);
        }
        request.setTimeout(envelope.timeoutMs == null ? endpoint.timeoutMs : envelope.timeoutMs);
        if (!String.isBlank(envelope.body)) {
            request.setBody(envelope.body);
        }

        try {
            result.response = new Http().send(request);
            result.statusCode = result.response.getStatusCode();
            result.responseBody = result.response.getBody();
            result.requestId = result.response.getHeader('X-Transaction-Id');
            result.safeSummary = buildSafeSummary(envelope.operationName, result.statusCode, result.correlationId, result.requestId);
            applyStatusClassification(result, result.statusCode);
            return result;
        } catch (CalloutException ex) {
            throw buildException(FailureCategory.TECHNICAL, null, result.correlationId, true, 'CALLOUT_EXCEPTION', ex.getMessage());
        }
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
        } else if (statusCode == 429 || statusCode == 500 || statusCode == 502 || statusCode == 503 || statusCode == 504) {
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

    private class EndpointConfig {
        public String key;
        public String namedCredential;
        public String basePath;
        public Integer timeoutMs;
    }

    @TestVisible
    static void setEndpointConfigTestData(List<SN_Endpoint_Config__mdt> endpointConfigs) {
        endpointConfigOverrides = endpointConfigs;
    }

    @TestVisible
    static void clearEndpointConfigTestData() {
        endpointConfigOverrides = null;
    }

    private static EndpointConfig getEndpointConfig(String orgKey) {
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
