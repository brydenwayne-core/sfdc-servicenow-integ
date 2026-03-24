# Failure Category Reference

## Purpose
Define failure categories, transaction status behavior, and support implications.

## Category mapping model

### Exception taxonomy categories (internal)
- `Configuration`
- `Mapping`
- `Routing`
- `Transport`
- `Security`
- `Idempotency`
- `UnsupportedBusiness`
- `Validation`
- `Unknown`

### Transaction log error categories (normalized)
- `Configuration`
- `Validation`
- `Transport`
- `Platform`
- `Security`
- `Unknown`

### Notable normalization behavior
- `Mapping` → `Validation`
- `Routing` → `Platform`
- `Idempotency` → `Platform`
- `UnsupportedBusiness` → `Validation`

## Transaction status and support intent

| Status | Meaning | Typical support action |
| --- | --- | --- |
| `Queued` | Awaiting processing | Verify queue movement and job health |
| `In Progress` | Execution in-flight | Monitor for timeout/stall; avoid duplicate retries |
| `Succeeded` | Completed successfully | Validate link integrity and close issue |
| `Retrying` | Retryable failure encountered | Diagnose root cause while backlog re-attempts |
| `Failed` | Terminal failure | Correct data/config/security issue before replay |
| `Abandoned` | Retry policy/processing halted | Engineering/admin review required |

## Category-by-category guidance

### 1) Configuration
**Signals**
- Missing org/request type/template/endpoint/toggle setup
- Frequent error codes: `ORG_CONFIG_MISSING`, `REQUEST_TYPE_MISSING`, `ENDPOINT_CONFIG_MISSING`, `FEATURE_DISABLED`

**Impact**
- Predictable, often immediate failures in specific org/request scopes.

**Response**
- Validate active CMT records and reference integrity.
- Run config validation and correct broken references.

**Escalate when**
- Multiple orgs impacted by shared endpoint/metadata drift.

---

### 2) Validation
**Signals**
- Pre-transport shape failures or downstream 4xx functional rejection.
- Frequent codes: `REQUEST_REQUIRED`, `ORG_KEY_REQUIRED`, `HTTP_SHAPE_INVALID`, `FUNCTIONAL_FAILURE`

**Impact**
- Single transaction or narrow request-type failures.

**Response**
- Correct source data, mapping, or request construction.
- Replay only after defect is confirmed fixed.

**Escalate when**
- Validation rules are unclear or inconsistently applied across environments.

---

### 3) Transport
**Signals**
- Timeouts, throttling, 5xx, callout exceptions.
- Frequent codes: `RETRYABLE_HTTP_FAILURE`, `CALLOUT_TIMEOUT`, `CALLOUT_EXCEPTION`

**Impact**
- Backlog increase, SLA delays, possible duplicate-risk scenarios.

**Response**
- Check service health, retry backlog, and duplicate risk.
- Prefer controlled replay over manual resubmission.

**Escalate when**
- Sustained 5xx/429/timeout rates exceed SLA or multi-org failure detected.

---

### 4) Platform
**Signals**
- Routing/idempotency conflicts, unsupported replay scenarios.
- May include custom exceptions mapped from `Routing` / `Idempotency` classes.

**Impact**
- Incorrect branch selection, replay confusion, or blocked operational recovery.

**Response**
- Validate routing criteria uniqueness and idempotency records.
- Avoid repeated manual retries until logic/state is corrected.

**Escalate when**
- Conflict is systemic and requires code-level remediation.

---

### 5) Security
**Signals**
- 401/403 and auth-related failures (`AUTH_FAILURE`).

**Impact**
- Broad outage potential for affected endpoint principal.

**Response**
- Stop retries that will continue to fail.
- Engage credential owners and security operations.

**Escalate when**
- Credential compromise, unauthorized changes, or prolonged outage risk.

---

### 6) Unknown
**Signals**
- `UNHANDLED_EXCEPTION`, unexpected HTTP codes, uncategorized failures.

**Impact**
- Uncertain blast radius; triage time increases.

**Response**
- Capture full correlation context and transaction timeline.
- Isolate whether issue is data-specific or systemic.

**Escalate when**
- Repeatable unknown failure pattern or production instability.
