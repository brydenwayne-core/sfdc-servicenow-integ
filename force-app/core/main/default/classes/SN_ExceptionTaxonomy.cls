public with sharing class SN_ExceptionTaxonomy {
    public enum FailureCategory { Configuration, Mapping, Routing, Transport, Security, Idempotency, UnsupportedBusiness, Validation, Unknown }

    public virtual class IntegrationException extends Exception {
        public FailureCategory category { get; private set; }
        public String code { get; private set; }
        public Boolean retryable { get; private set; }
        public IntegrationException(FailureCategory category, String code, String message, Boolean retryable) {
            this.category = category == null ? FailureCategory.Unknown : category;
            this.code = code;
            this.retryable = retryable;
            super(message);
        }
    }
    public class ConfigurationException extends IntegrationException { public ConfigurationException(String c, String m){ super(FailureCategory.Configuration,c,m,false);} }
    public class MappingException extends IntegrationException { public MappingException(String c, String m){ super(FailureCategory.Mapping,c,m,false);} }
    public class RoutingException extends IntegrationException { public RoutingException(String c, String m){ super(FailureCategory.Routing,c,m,false);} }
    public class TransportException extends IntegrationException { public TransportException(String c, String m, Boolean r){ super(FailureCategory.Transport,c,m,r);} }
    public class AuthException extends IntegrationException { public AuthException(String c, String m){ super(FailureCategory.Security,c,m,false);} }
    public class IdempotencyConflictException extends IntegrationException { public IdempotencyConflictException(String c, String m){ super(FailureCategory.Idempotency,c,m,true);} }
    public class UnsupportedBusinessException extends IntegrationException { public UnsupportedBusinessException(String c, String m){ super(FailureCategory.UnsupportedBusiness,c,m,false);} }

    public static String toErrorCategory(FailureCategory category) {
        if (category == FailureCategory.Configuration) return 'Configuration';
        if (category == FailureCategory.Mapping) return 'Validation';
        if (category == FailureCategory.Routing) return 'Platform';
        if (category == FailureCategory.Transport) return 'Transport';
        if (category == FailureCategory.Security) return 'Security';
        if (category == FailureCategory.Idempotency) return 'Platform';
        if (category == FailureCategory.UnsupportedBusiness) return 'Validation';
        if (category == FailureCategory.Validation) return 'Validation';
        return 'Unknown';
    }
    public static String toFailureClass(FailureCategory category) {
        return String.valueOf(category == null ? FailureCategory.Unknown : category);
    }
}
