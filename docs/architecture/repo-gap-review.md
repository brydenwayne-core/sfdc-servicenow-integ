# Repository Architectural Gap Review

_Date:_ 2026-03-23  
_Scope:_ full Salesforce DX repository review for an enterprise healthcare Salesforce-to-ServiceNow integration package.  
_Intent:_ establish a refinement baseline before more implementation is added.

## Executive Summary

This repository has a solid metadata-driven foundation, but it is **not yet enterprise-ready as a healthcare integration package**. The largest gaps are not cosmetic—they affect runtime correctness, packaging reliability, operational safety, and admin trust.

The most material issues are:

1. **Architecture drift between docs and implementation**: the repository describes a packageable, metadata-driven framework, but several runtime services remain placeholders or legacy facades.
2. **Duplicate observability models**: there are parallel transaction/error concepts (`Integration_*` and `SN_Integration_*`) with overlapping purpose but different implementation maturity.
3. **Incomplete security hardening**: Apex runs `with sharing`, but there is no consistent CRUD/FLS enforcement, no explicit secret-rotation/admin boundary model, and broad admin/operator permissions could overexpose operational data.
4. **Packaging/admin usability gaps**: packaging directories are defined, but there is no clear package-version strategy, no install/upgrade guidance, and admin UX is still largely object-tab driven.
5. **Brittle generated implementation seams**: multiple classes are placeholders, default-org assumptions are hardcoded, and some orchestration behavior bypasses abstractions the repository claims to rely on.

## Review Method

This review inspected:

- repository structure and packaging model,
- Apex service layer and tests,
- custom objects / custom metadata design,
- permission sets and credential metadata,
- CI/quality-gate scripts and workflow,
- architecture/admin/support documentation.

## Critical Findings

### C1. Observability and admin data model are duplicated and internally inconsistent

The repository currently carries **two overlapping observability models**:

- production-facing objects: `Integration_Transaction__c` and `Integration_Error__c`
- admin-facing/future objects: `SN_Integration_Run__c` and `SN_Integration_Error__c`

This creates architectural ambiguity:

- runtime orchestration writes to `Integration_Transaction__c`, not `SN_Integration_Run__c`
- admin permission sets expose `SN_Integration_Run__c` and `SN_Integration_Error__c`, but not `Integration_Error__c`
- support docs tell operators to inspect either error object “if present,” which signals the model is unresolved rather than intentionally normalized

**Risk:** support teams, packagers, and future developers will not know which model is canonical. This will fragment reporting, permissions, and future automation.

**Refinement direction:** choose one canonical runtime/admin observability model, deprecate the other, and align permission sets, layouts, tabs, runbooks, and tests.

### C2. Core runtime architecture is incomplete behind placeholder classes

Several classes advertise architectural boundaries but do not implement them:

- `SN_RequestRouter` is a placeholder
- `SN_RequestBuilder` returns `null`
- `SN_ResponseHandler` is empty
- `SN_NamedCredentialResolver` is a placeholder
- `SN_MetadataConfigService` is only a legacy facade

This matters because the repository narrative says orchestration, transport, transformation, and configuration are separated, but the actual orchestration path bypasses some of those seams directly. That means the architecture is only partially real.

**Risk:** future work may stack on top of placeholder boundaries and create even more coupling, making later refactoring expensive.

**Refinement direction:** either complete these seams and route production flow through them, or remove them until they are truly needed.

### C3. Hardcoded default-org behavior undermines the multi-org architecture claim

Despite positioning the solution as multi-org and metadata-driven, there are still hardcoded default-org assumptions:

- `SN_IntegrationOrchestrator.resolveOrgKey()` falls back to `DEFAULT`
- `SN_CaseIntakeController` always submits with org key `DEFAULT`
- `SN_CaseIntakeSupport` also defaults to `DEFAULT`

This is a brittle shortcut in an architecture whose central promise is org-specific configuration via metadata.

**Risk:** production deployments could fail unexpectedly unless a `DEFAULT` org config is created everywhere, and future org onboarding may silently route through the wrong tenant context.

**Refinement direction:** replace `DEFAULT` with an explicit org-resolution strategy (e.g., org metadata lookup, platform cache/context provider, or caller-supplied context with validation).

### C4. Security posture is not enterprise-healthcare ready yet

The repo’s intent is security-conscious, but the implementation is incomplete:

- there is no systematic CRUD/FLS enforcement on reads/writes to Cases and custom objects
- there is no use of `WITH SECURITY_ENFORCED` / `Security.stripInaccessible()` patterns
- operator/admin permission sets are broad and focused on object access, not least-privilege operational tasks
- credential metadata is skeletal, with a placeholder endpoint and no admin/runbook model for principal setup, secret rotation, or environment promotion

**Risk:** this will not satisfy a serious enterprise security review, especially in healthcare where auditors will ask for object access boundaries, least-privilege controls, and PHI-safe logging assurances beyond best intent.

**Refinement direction:** establish a formal security hardening backlog covering CRUD/FLS policy, execution context decisions, permission set segmentation, credential operating model, and secure admin UX.

### C5. Packaging readiness is partial rather than real

The package directory split is good, but packaging readiness is still immature:

- no namespace strategy is documented
- no package version promotion/install strategy is documented
- no install prerequisites or post-install steps are documented
- sample config depends on core, but there is no packaging contract for which metadata is customer-editable vs sample-only
- manifests are broad `*` manifests, which is convenient for retrieval but not strong package governance

**Risk:** this repo can be deployed as source, but it is not yet operationally ready as a clean enterprise package line with predictable upgrades.

**Refinement direction:** define package boundaries, upgrade expectations, mutable metadata policy, and install/deployment runbooks.

## Important Findings

### I1. Documentation and repository structure have drifted from the actual codebase

The repo structure document says the primary Salesforce metadata source is `force-app/main/default/`, but the actual implementation is split across `force-app/core`, `force-app/admin`, and `force-app/sample-config`.

This is a strong signal that repo documentation has not kept up with the generated structure.

**Why it matters:** architecture docs become untrustworthy quickly when they describe a different topology than the actual repo. That damages onboarding and future AI-assisted generation.

### I2. Runtime orchestration is more tightly coupled than the design suggests

The orchestrator owns a large amount of coordination logic directly:

- loading the Case
- feature toggle enforcement
- request-type validation
- idempotency reservation
- routing context assembly
- payload assembly
- ServiceNow invocation
- transaction success/failure updates
- incident link updates

Although there are injectable gateways, the orchestrator is still a heavy “god service.”

**Why it matters:** new capabilities such as comment sync, inbound updates, or alternate source objects will likely cause this class to grow instead of composing cleaner domain services.

**Refinement direction:** move to a command pipeline / handler model or operation-specific services with shared cross-cutting services.

### I3. Observability is useful but not yet complete enough for enterprise operations

Current transaction logging captures status, correlation IDs, idempotency, and safe summaries, which is a good start. However, observability still has major gaps:

- no platform events or alerts for failure states
- no dead-letter / abandonment policy beyond status values
- no structured metrics or support dashboard metadata
- no batch reconciliation job for drift detection between Salesforce and ServiceNow
- no explicit retention/archive strategy for transaction/error objects

**Why it matters:** enterprise integration support needs both record-level traceability and org-level operational telemetry.

### I4. Error handling is only partially normalized

Failures are logged, but child error object usage is inconsistent, response handling is not centralized, and retry semantics are basic.

Examples of incomplete maturity:

- `SN_ResponseHandler` exists but is not used
- retryable failures move records to `Retrying`, but retry policy/max attempts/backoff are not represented in metadata
- unhandled exceptions are logged with a generic code, but escalation context is thin

**Refinement direction:** define a first-class error taxonomy, retry policy metadata, and standardized response/error handlers.

### I5. Metadata model is promising but still thin for real-world healthcare implementations

The custom metadata foundation is solid, but not yet rich enough for enterprise complexity:

- no environment-scoped policy metadata beyond org and endpoint keys
- no validation-rule metadata for pre-callout business checks
- no field-level redaction/classification metadata
- no metadata for retry policy, SLA tier, throttling strategy, or source-object enablement
- routing criteria rely on JSON in a text field, which is flexible but fragile and hard for admins to validate

**Why it matters:** healthcare integrations evolve through operational policy and governance changes, not just field mapping changes.

### I6. Test architecture is better than average, but still optimistic compared to package reality

There are reusable test factories and a decent metadata-mocking pattern. That said, the tests are mostly happy-path/unit-style simulations.

Remaining gaps:

- no packaging/install validation tests
- no negative security tests
- no tests for metadata ambiguity/admin misconfiguration at scale
- no tests around permission set visibility/usability
- no tests proving sample config and package directory boundaries behave correctly during deployment

**Refinement direction:** add metadata contract tests, packaging smoke tests, and security/negative-path scenarios.

### I7. Admin usability is functional but still low-maturity

The admin layer currently centers on tabs, layouts, and permission sets. That gives visibility, but not a polished admin operating experience.

Missing admin usability features include:

- guided setup / onboarding checklist
- health dashboard / home page analytics
- list views/reports for key failure cohorts across all exposed objects
- admin validation tools for configuration completeness
- safer UX for retry actions and duplicate-risk review

**Why it matters:** a metadata-driven architecture only works operationally if admins can confidently reason about the metadata and runtime state.

## Opportunistic Findings

### O1. Legacy and future-facing abstractions should be rationalized early

There are several signs of generated architectural drift:

- placeholder classes retained for future use
- legacy facades retained while callers “migrate” even though the repo is still early-stage
- duplicate runtime/admin object families

Cleaning this up now will be much cheaper than after more features land.

### O2. CI quality gates are useful, but not yet enterprise-complete

Current scripts cover static analysis, Apex tests, metadata validation, and package checks. Missing or future-improving areas include:

- package version creation validation in CI
- destructive-change guardrails
- documentation linting / link checks
- PMD rule tuning specific to Apex integration/security patterns
- artifact publication of coverage summaries and scanner findings in PR-friendly form

### O3. Admin/sample metadata separation is conceptually right and should be preserved

The split between core/admin/sample-config is one of the stronger design choices in the repo. It should remain, but it needs clearer contracts and documentation around what is installable, editable, and environment-specific.

### O4. File/comment/status sync roadmap should be turned into explicit extension points

The repo already hints at future comment/file/status sync. Converting those hints into an explicit extension roadmap or ADR set would prevent ad hoc growth in the orchestrator.

## Brittle Patterns Likely Introduced by Generated Code

These patterns are especially worth addressing because they are typical AI-generated shortcuts that tend to calcify if not corrected quickly.

1. **Placeholder abstraction pattern**  
   Classes exist to suggest layered architecture, but production flow does not actually rely on them yet.

2. **“DEFAULT” context fallback pattern**  
   Multi-org complexity is hidden behind hardcoded fallback values instead of an explicit context-resolution design.

3. **Duplicate model pattern**  
   Similar custom objects were created for “now” and “future,” leaving canonical ownership unresolved.

4. **God orchestrator pattern**  
   A single orchestration class is carrying too many responsibilities, even though supporting services exist.

5. **JSON-in-text admin contract pattern**  
   Routing criteria are flexible but brittle, hard to validate, and easy for admins to misconfigure.

6. **Documentation optimism pattern**  
   Docs describe the intended architecture more strongly than the implementation currently proves.

7. **Test confidence inflation pattern**  
   Tests validate the designed behavior under mocks, but there are not enough repo/package/permission-level checks to justify full enterprise confidence yet.

## Prioritized Refinement Backlog

### Critical priority backlog

1. **Choose and normalize the canonical observability model**
   - Decide whether `Integration_*` or `SN_Integration_*` is the supported runtime/admin model.
   - Remove or deprecate the duplicate family.
   - Align tabs, permission sets, layouts, reports, runbooks, and tests.

2. **Eliminate hardcoded `DEFAULT` org behavior**
   - Introduce an explicit org-context resolver.
   - Make missing org context a deliberate, diagnosable error when appropriate.
   - Update intake/admin docs accordingly.

3. **Resolve placeholder architecture seams**
   - Either implement `SN_RequestBuilder`, `SN_ResponseHandler`, `SN_RequestRouter`, and `SN_NamedCredentialResolver`, or retire them for now.
   - Ensure the final runtime path reflects the documented architecture.

4. **Create a security hardening baseline**
   - Define CRUD/FLS approach for runtime reads/writes.
   - Review permission sets for least privilege.
   - Document credential setup, secret rotation, and environment segregation.
   - Add security-focused tests/checks.

5. **Define real packaging readiness criteria**
   - Document package install order and post-install setup.
   - Clarify editable metadata vs packaged sample data.
   - Add package version creation validation and upgrade readiness tasks.

### Important priority backlog

6. **Break up the orchestrator into operation-specific services or pipeline stages**
7. **Introduce metadata-backed retry policy and error taxonomy controls**
8. **Add richer observability: reporting assets, alerts/events, reconciliation jobs, retention policy**
9. **Repair documentation drift and make docs match the repo exactly**
10. **Add contract tests for metadata ambiguity, misconfiguration, and package boundaries**
11. **Improve admin usability with setup guidance, health views, and safer operational actions**

### Opportunistic backlog

12. **Replace JSON text routing criteria with a more governable pattern or validator**
13. **Add documentation linting and repo-structure consistency checks in CI**
14. **Define extension ADRs for comments, attachments, inbound sync, and reconciliation**
15. **Introduce dashboards/reports as first-class admin package assets**
16. **Add data lifecycle guidance for transaction/error record growth**

## Suggested Next Refinement Sequence

1. Observability model consolidation  
2. Org-context resolution and intake architecture cleanup  
3. Security hardening baseline  
4. Placeholder seam resolution / orchestrator decomposition  
5. Packaging/admin usability improvements  
6. Advanced observability and reconciliation roadmap

## Overall Assessment

**Current maturity:** strong foundation / early enterprise prototype  
**Architectural direction:** good  
**Implementation consistency:** mixed  
**Packaging readiness:** partial  
**Security readiness:** partial  
**Admin-operability readiness:** partial

This repo is in a good position for a **refinement-first phase**. The right move is not to add more features immediately, but to tighten the architecture so future work lands on a cleaner, more governable baseline.
