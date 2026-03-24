# Error Code Catalog

## Purpose
Provide a formal reference for error codes emitted by the integration and the expected support response.

## How to use
1. Locate `Integration_Transaction__c.ErrorCode__c`.
2. Cross-reference category and retryability.
3. Follow remediation and verification steps.
4. Escalate by issue type when criteria are met.

## Catalog

| Error Code | Source Layer | Typical Category | Retryable | Likely Causes | Operational Impact | Primary Remediation | Verification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `FEATURE_DISABLED` | Orchestrator pre-check | Configuration | No | Required feature toggle disabled at org/request-type scope or kill switch active | No outbound request; business flow blocked | Enable correct toggle or disable kill switch intentionally; confirm dependency toggles | New transaction proceeds to `In Progress` and then `Succeeded` |
| `ORG_CONFIG_MISSING` | Configuration validation | Configuration | No | Missing/inactive `SN_Org_Config__mdt` for org key | Org cannot process transactions | Create/activate org config and endpoint key mapping | Config validation clears; transaction no longer fails at pre-check |
| `ENDPOINT_CONFIG_MISSING` | Configuration validation | Configuration | No | Missing/inactive endpoint metadata for org | Transport cannot start | Activate `SN_Endpoint_Config__mdt` and verify Named Credential mapping | Transaction no longer fails before callout |
| `REQUEST_TYPE_MISSING` | Configuration validation | Configuration | No | Request type not configured or inactive | Request type blocked | Create/activate `SN_Request_Type__mdt` and dependencies | Request type appears and transaction processes |
| `INCIDENT_TEMPLATE_MISSING` | Configuration validation | Configuration | No | Template key absent/inactive for request type | Payload cannot be built consistently | Create/activate `SN_Incident_Template__mdt` and verify reference | Template resolution succeeds in test run |
| `REPLAY_NOT_ALLOWED` | Replay service | Validation / Unsupported business | No | Replay attempted on ineligible status or security-restricted record | Recovery delayed | Reassess root cause; use proper replay-eligible records only | Replay call succeeds only on `Failed`/`Retrying`/`Abandoned` + eligible flag |
| `REQUEST_REQUIRED` | ServiceNow client pre-transport validation | Validation | No | Null request envelope | Processing halts before callout | Correct caller logic / orchestration invocation | No pre-transport validation failure in repeat test |
| `ORG_KEY_REQUIRED` | ServiceNow client pre-transport validation | Validation | No | Missing org key in request envelope | Processing halts before callout | Ensure org key is resolved and passed | Envelope validation passes |
| `HTTP_SHAPE_INVALID` | ServiceNow client pre-transport validation | Validation | No | Missing method or relative path | No callout | Correct request construction | Callout request is built and sent |
| `MISSING_ENDPOINT_CONFIG` | ServiceNow client endpoint resolver | Configuration | No | Resolved endpoint lacks Named Credential | No callout to ServiceNow | Fix endpoint metadata and Named Credential value | Request endpoint resolves as `callout:<NamedCredential>/...` |
| `AUTH_FAILURE` | HTTP response classifier (401/403) | Security | No | Expired credentials, revoked principal, permission drift | All/most requests fail in impacted scope | Credential rotation/repair, principal permission correction | 401/403 cleared; success transactions observed |
| `FUNCTIONAL_FAILURE` | HTTP response classifier (400/404/409/422) | Validation | No | Payload/data issue, missing referenced resource, business rule rejection | Individual transaction fails; no safe retry | Correct mapping/source data/reference IDs | Replayed transaction succeeds without additional config errors |
| `RETRYABLE_HTTP_FAILURE` | HTTP response classifier (408/429/5xx gateway errors) | Transport | Yes | Timeouts, throttling, temporary ServiceNow outage | Backlog growth and delays | Wait/retry per policy; coordinate external status; replay eligible items | Failure rate drops and retries converge to success |
| `HTTP_FAILURE` | HTTP response classifier (other non-2xx) | Transport/Unknown | Usually No | Unexpected status or unclassified downstream behavior | Unclear; may require engineering analysis | Capture response metadata, escalate with correlation IDs | Root cause identified; category normalized in follow-up |
| `CALLOUT_TIMEOUT` | Callout exception mapper | Transport | Yes | Network latency, downstream saturation, timeout too low | High duplicate risk if remote commit uncertain | Validate whether incident was created before replay; tune timeout if systemic | Replay succeeds without duplicate creation |
| `CALLOUT_EXCEPTION` | Callout exception mapper | Transport | Contextual | DNS/TLS/network/runtime callout exception | Partial outage or intermittent failures | Validate platform/network health and endpoint reachability; retry where safe | Exception trend resolved and requests complete |
| `UNHANDLED_EXCEPTION` | Orchestrator catch-all | Unknown | No | Unanticipated code path or data edge case | Transaction fails terminally | Escalate to engineering with correlation + stack context | Patch deployed and failure no longer reproducible |

## Notes
- Category shown in logs may be normalized (`Mapping` failures can appear as `Validation`; some platform-specific classes map to `Platform`).
- Retryability in this table reflects current implementation behavior and should be revalidated after major releases.
