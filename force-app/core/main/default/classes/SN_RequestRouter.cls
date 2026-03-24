public with sharing class SN_RequestRouter {
    public class RouteContext {
        public String operationName;
        public String requestTypeKey;
        public String orgKey;
    }

    public interface IRouteHandler {
        Object execute(RouteContext context, Object requestPayload);
    }

    private static Map<String, IRouteHandler> handlersByOperation = new Map<String, IRouteHandler>();

    public static void register(String operationName, IRouteHandler handler) {
        if (String.isBlank(operationName) || handler == null) {
            return;
        }
        handlersByOperation.put(operationName.trim().toLowerCase(), handler);
    }

    public static Object route(RouteContext context, Object requestPayload) {
        if (context == null || String.isBlank(context.operationName)) {
            throw new RequestRouterException('Operation name is required for request routing.');
        }
        String key = context.operationName.trim().toLowerCase();
        if (!handlersByOperation.containsKey(key)) {
            throw new RequestRouterException('No request handler registered for operation ' + context.operationName + '.');
        }
        return handlersByOperation.get(key).execute(context, requestPayload);
    }

    @TestVisible
    static void reset() {
        handlersByOperation.clear();
    }

    public class RequestRouterException extends Exception {}
}
