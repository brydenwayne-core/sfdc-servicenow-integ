# Component Model

## Purpose
Map code-level components to architectural responsibilities.

## Component Responsibilities

| Component | Responsibility |
| --- | --- |
| `SN_IntegrationOrchestrator` | Coordinates config resolution, payload assembly, transport invocation, and result handling. |
| `SN_IncidentOrchestrationService` | Incident-specific orchestration policy and flow composition. |
| `SN_ConfigService` / `SN_MetadataConfigService` | Loads and shapes metadata-driven configuration contracts. |
| `SN_ConfigValidationService` | Validates metadata integrity and readiness for execution. |
| `SN_FeatureToggleService` | Evaluates runtime feature enablement/kill-switch posture. |
| `SN_FieldMappingService` / `SN_IncidentPayloadBuilder` | Converts Salesforce context into ServiceNow incident payload model. |
| `SN_RoutingService` / `SN_RequestRouter` | Selects assignment and routing outcome based on rules/priority criteria. |
| `SN_ServiceNowClient` / `SN_RequestBuilder` / `SN_ResponseHandler` | Handles REST request construction, API call execution, and response interpretation. |
| `SN_IdempotencyService` | Guards duplicate processing and idempotent execution semantics. |
| `SN_TransactionLogService` | Persists status and error context for support operations. |
| `SN_TransactionReplayService`, `SN_TransactionRetryQueueable`, `SN_IncidentSyncQueueable`, `SN_FileSyncQueueable` | Reliability workflows for asynchronous retry/replay/sync operations. |
| `SN_ExceptionTaxonomy` | Standardized failure classification and retry semantics. |
| `SN_IncidentLinkService` | Maintains linkage between Salesforce records and ServiceNow incidents. |

## Architectural Boundaries

- Domain logic remains in orchestrator/services.
- Metadata contract logic remains in config services.
- Transport concerns remain isolated in client/request/response components.
- Support lifecycle concerns remain in transaction/error services and queueables.

## Cross-links

- [Logical Architecture](logical-architecture.md)
- [Metadata Architecture](metadata-architecture.md)
- [Observability Architecture](observability-architecture.md)
- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
