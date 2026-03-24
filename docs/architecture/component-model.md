# Component Model

## Purpose
Map implemented classes/services/objects to architectural responsibilities and ownership concerns.

## Runtime Components

| Component | Responsibility | Primary Dependency Type |
| --- | --- | --- |
| `SN_IntegrationOrchestrator` | End-to-end orchestration coordination | Config, transport, observability |
| `SN_IncidentOrchestrationService` | Incident-specific orchestration rules | Mapping, routing, validation |
| `SN_ConfigService` / `SN_MetadataConfigService` | Metadata loading and shaping | Custom metadata |
| `SN_ConfigValidationService` | Configuration readiness checks | Metadata + admin process |
| `SN_FeatureToggleService` | Runtime feature enablement/kill switch evaluation | Toggle metadata |
| `SN_FieldMappingService` / `SN_IncidentPayloadBuilder` | Outbound payload construction | Mapping/template metadata |
| `SN_RoutingService` / `SN_RequestRouter` | Assignment and routing decisions | Routing/assignment metadata |
| `SN_ServiceNowClient` / `SN_RequestBuilder` / `SN_ResponseHandler` | Transport execution and API response interpretation | Named Credential + API contract |
| `SN_IdempotencyService` | Duplicate prevention and execution safety | Runtime transaction state |
| `SN_TransactionLogService` | Transaction/run/error telemetry persistence | Runtime objects |
| `SN_TransactionReplayService` + retry/sync queueables | Controlled recovery and deferred processing | Queue infrastructure + failure policy |
| `SN_IncidentLinkService` | Salesforce ↔ ServiceNow record correlation | Link object |
| `SN_ExceptionTaxonomy` | Failure-class standards and retry semantics | Error handling policy |

## Metadata Components

| Metadata Type | Responsibility |
| --- | --- |
| `SN_Org_Config__mdt` | Org profile, endpoint key, environment context |
| `SN_Request_Type__mdt` | Request semantics and execution mode |
| `SN_Field_Mapping__mdt` | Source-to-target field transformations |
| `SN_Incident_Template__mdt` | Template-level payload defaults |
| `SN_Routing_Rule__mdt` | Rule-driven route selection |
| `SN_Assignment_Target__mdt` | ServiceNow assignee references |
| `SN_Feature_Toggle__mdt` | Rollout controls and kill switches |
| `SN_Endpoint_Config__mdt` | Named Credential and endpoint path indirection |

## Operational Data Components

- `Integration_Transaction__c`
- `Integration_Error__c`
- `SN_Integration_Error__c`
- `SN_Integration_Run__c`
- `ServiceNow_Incident_Link__c`

## Cross-links

- [Logical Architecture](logical-architecture.md)
- [Metadata Architecture](metadata-architecture.md)
- [Observability Architecture](observability-architecture.md)
- [Package Modularity Overview](package-modularity-overview.md)
- [Failure Classification Flow](../process/failure-classification-and-triage.md)
