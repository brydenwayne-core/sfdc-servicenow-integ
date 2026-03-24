# Logical Architecture

## Purpose
Describe the end-to-end logical flow, capability layers, and control points used by the implemented integration.

## Capability Layers

1. **Intake orchestration layer**
   - `SN_CaseIntakeController`, `SN_CaseIntakeSupport`, `SN_IntegrationOrchestrator`, `SN_IncidentOrchestrationService`.
2. **Configuration/policy layer**
   - `SN_ConfigService`, `SN_MetadataConfigService`, `SN_FeatureToggleService`, `SN_ConfigValidationService`.
3. **Transformation/routing layer**
   - `SN_FieldMappingService`, `SN_IncidentPayloadBuilder`, `SN_RoutingService`, `SN_RequestRouter`, `SN_PayloadValidationService`.
4. **Transport layer**
   - `SN_ServiceNowClient`, `SN_RequestBuilder`, `SN_ResponseHandler`, `SN_NamedCredentialResolver`.
5. **Reliability layer**
   - `SN_IdempotencyService`, `SN_TransactionRetryQueueable`, `SN_TransactionReplayService`, sync queueables.
6. **Observability layer**
   - `SN_TransactionLogService`, transaction/error/run/link objects.

## Nominal Flow

1. Intake logic identifies request intent from Case context.
2. Metadata bundle is resolved by org/request key.
3. Payload mapping, template merge, and routing resolution occur.
4. Callout executes via Named Credential.
5. Response classification updates link and transaction telemetry.
6. Retry/replay path is activated for eligible failures.

## Control Points

- **Feature toggles:** request/org/global enablement and kill switch behavior.
- **Idempotency:** duplicate prevention for replay/retry and concurrent triggers.
- **Failure taxonomy:** classifies errors for operator decision trees.
- **Lifecycle state:** enables measurable queue health and backlog review.

## Enterprise Quality Attributes

- **Reusability:** metadata variation over code branching.
- **Operability:** deterministic support telemetry and replay mechanisms.
- **Security:** no embedded secrets; controlled callout endpoints.
- **Governability:** package boundaries + lifecycle-aware metadata.

## Cross-links

- [System Context](system-context.md)
- [Component Model](component-model.md)
- [Metadata Architecture](metadata-architecture.md)
- [Observability Architecture](observability-architecture.md)
- [Incident Update to Case Sync Flow](../process/incident-update-to-case-sync.md)
- [Metadata-Driven Routing Flow](../process/metadata-driven-routing.md)
