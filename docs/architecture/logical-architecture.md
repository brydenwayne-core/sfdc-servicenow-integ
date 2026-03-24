# Logical Architecture

## Purpose
Describe the logical processing flow and capability layers implemented in the repository.

## Capability Layers

1. **Intake and orchestration layer**
   - `SN_CaseIntakeController`, `SN_CaseIntakeSupport`, `SN_IntegrationOrchestrator`, `SN_IncidentOrchestrationService`.
2. **Configuration and policy layer**
   - `SN_ConfigService`, `SN_MetadataConfigService`, `SN_FeatureToggleService`, `SN_ConfigValidationService`.
3. **Transformation and routing layer**
   - `SN_FieldMappingService`, `SN_IncidentPayloadBuilder`, `SN_RoutingService`, `SN_RequestRouter`.
4. **Transport and external API layer**
   - `SN_ServiceNowClient`, `SN_RequestBuilder`, `SN_ResponseHandler`, `SN_NamedCredentialResolver`.
5. **Reliability and lifecycle layer**
   - `SN_IdempotencyService`, retry/replay queueables/services, exception taxonomy.
6. **Observability and support layer**
   - `SN_TransactionLogService`, runtime transaction/error/link/run objects, admin artifacts.

## End-to-End Flow (Nominal)

1. Case context is evaluated for eligible request type.
2. Metadata bundle is resolved for org/request/routing/mapping/toggles.
3. Payload is built and validated.
4. ServiceNow callout executes through named credential-backed endpoint.
5. Response is interpreted, link/transaction state is updated, and errors are categorized.
6. Retry/replay lifecycle proceeds for eligible failures.

## Non-Functional Design Intent

- **Scalability:** org variability modeled through metadata, not code forks.
- **Governance:** explicit separation between runtime logic and admin-owned config.
- **Supportability:** deterministic status/error categorization and replay controls.
- **Security:** no embedded secrets, minimized log payloads.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Component Model](component-model.md)
- [Metadata Architecture](metadata-architecture.md)
- [Observability Architecture](observability-architecture.md)
- [Test Architecture](test-architecture.md)
