# Project Context + Requirements + Architecture Overview

## 1. Context

UCLA Health needs a reusable Salesforce-based integration framework that connects ServiceNow incidents with Salesforce Cases across multiple Salesforce orgs. The immediate delivery target is an Apex-based integration between one ServiceNow instance and the EnterpriseCRM Salesforce org, but the solution must establish a repeatable architectural pattern that can expand from the current three Salesforce orgs to as many as ten over time.

The solution should be designed as a metadata-driven application framework rather than a one-off point integration. That framework should support structured issue intake in Salesforce, metadata-based routing and translation, secure REST-based connectivity to ServiceNow, and operational logging that gives support teams visibility into transaction status and errors.

This direction aligns with Salesforce architecture guidance around metadata-driven design, adaptable architecture, secure external connectivity, and resilient integration patterns. It also reflects a service-management principle that structured intake produces better data quality, more accurate routing, and better downstream support outcomes.

## 2. Current-State Constraints

The architecture must account for several important constraints in the current operating environment:

- The current ServiceNow incident and Salesforce Case process is still maturing.
- Routing rules, field mappings, and assignment logic are expected to change.
- Different Salesforce orgs may require different intake experiences and routing configurations.
- Long-term ownership is expected to grow beyond the team’s current three orgs.
- The initial solution needs to solve an immediate business problem without locking the organization into brittle logic or org-specific forks.

Because of those constraints, the design should treat the current process model as provisional rather than final. Stable technical components should live in Apex and platform configuration, while business process decisions that are likely to change should be represented in deployable metadata.

## 3. Design Principles

### 3.1 Metadata over code

Apex should own the reusable framework concerns:

- orchestration,
- validation,
- translation execution,
- integration transport,
- logging,
- retry handling,
- and error management.

Metadata should own business and org-specific variation:

- org definitions,
- ticket or request types,
- routing rules,
- assignment targets,
- field mappings,
- incident templates,
- queue mappings,
- active or inactive controls,
- and feature toggles.

This reduces the cost of change and allows administrators to evolve process behavior without modifying Apex for every change request.

### 3.2 Configurable multi-org architecture

Each Salesforce org should be treated as a configurable tenant of the framework, even when the solution is deployed separately by environment or org. The same application pattern should be installable and adaptable with org-specific metadata records.

Recommended configuration entities include:

- **Org Configuration**,
- **Ticket Type / Request Type**,
- **Field Mapping**,
- **Routing Rule**,
- **Assignment Rule**,
- **Feature Toggle**,
- **Integration Endpoint / Named Credential Reference**,
- and **Incident Template**.

### 3.3 Separation of concerns

The architecture should be layered so that process changes can be made without destabilizing transport logic or UI behavior. The primary logical layers are:

- **UI / Intake Layer**,
- **Business Rules Layer**,
- **Mapping / Translation Layer**,
- **Integration Service Layer**,
- and **Logging / Monitoring Layer**.

### 3.4 Security by design

All external connectivity should use Salesforce-supported secure credential management, especially Named Credentials and External Credentials. Secrets must not be stored in Apex, custom settings, or ad hoc configuration. Logging must redact sensitive values, and access should follow least-privilege principles using dedicated integration identities.

### 3.5 Resilience and asynchronous processing

Not every interaction requires a synchronous user wait state. The design should use synchronous processing only when the user needs immediate confirmation, such as submission acknowledgment. For non-immediate operations, the framework should support asynchronous orchestration, retries, and safe recovery to improve scale and resilience.

### 3.6 Admin-owned evolution

The target operating model should allow future changes to be made primarily by administrators or support owners through metadata updates, templates, and toggles instead of repeated Apex rewrites.

## 4. Functional Requirements

The solution must support the following functional requirements:

1. Users must be able to submit a Salesforce support issue through a structured intake experience.
2. A submitted intake must create or update a Salesforce Case that represents the support issue.
3. The Case must be translated into a ServiceNow incident payload using configurable mapping rules.
4. The solution must support multiple Salesforce orgs using a common architectural pattern.
5. The solution must support org-specific routing, assignment, and field mapping behavior.
6. The solution must store and track the resulting ServiceNow incident identifier on the Salesforce side.
7. The solution must support future inbound updates from ServiceNow into Salesforce Cases.
8. The solution must support a phased evolution from simple case submission toward richer catalog-style request templates and bidirectional synchronization.

## 5. Configuration Requirements

The solution must meet the following configuration requirements:

1. Org definitions, request types, assignment rules, and routing rules must be configurable without code changes.
2. Field mappings between Salesforce and ServiceNow must be configurable through deployable metadata.
3. New request or incident types must be addable without large-scale Apex refactoring.
4. Org rollout from three orgs toward ten orgs must reuse the same framework and avoid org-specific branches wherever possible.
5. Feature rollout should support active or inactive flags and optional feature toggles to enable phased adoption.
6. Endpoint references and connection behavior should be configurable by environment and org using supported platform mechanisms.

## 6. Security Requirements

The solution must meet the following security requirements:

1. Authentication and endpoint management must use platform-supported secure credential management such as Named Credentials and External Credentials.
2. Secrets must not be embedded in Apex code.
3. Logging must avoid storing sensitive data in clear text and should redact request or response fields when appropriate.
4. The design must support least-privilege integration access with dedicated service principals.
5. The solution must be reviewable for enterprise security and audit requirements.
6. Access to configuration and operational tooling must be restricted according to administrator and support roles.

## 7. High-Level Architecture

### 7.1 End-to-end flow

The core business flow is:

1. A Salesforce user submits a guided issue intake or creates a Case.
2. Salesforce determines the source org, request type, required fields, and routing using metadata.
3. Apex orchestration services validate the request and assemble a ServiceNow payload.
4. A ServiceNow client service performs a secure REST callout using a Named Credential.
5. The response is stored on the related Case and captured in an integration transaction log.
6. Follow-on updates, retries, or synchronization events are processed by the framework as the integration matures.

### 7.2 Logical components

#### A. Guided intake experience

The initial intake experience should use standard Salesforce UX capabilities such as Case record pages and Screen Flows. The experience should gather structured data including:

- issue category,
- subcategory,
- impacted org or application,
- severity or urgency,
- assignment target,
- attachment requirements,
- and user guidance or instructions.

This intake can later evolve toward a more catalog-style model as the operating process matures.

#### B. Metadata-driven request model

The selected request type should determine:

- required fields,
- validation rules,
- incident template,
- ServiceNow assignment group,
- Salesforce case queue,
- and source-to-target field mappings.

#### C. Apex orchestration services

Recommended core service classes include:

- `IncidentIntakeService`,
- `FieldMappingService`,
- `RoutingService`,
- `ServiceNowClient`,
- `IncidentSyncService`,
- and `IntegrationLogService`.

These services should be cohesive, testable, and separated by concern.

#### D. Configuration layer

Custom Metadata Types are the preferred mechanism for durable, deployable, and package-friendly configuration. This layer should store the org-specific and request-specific records that shape runtime behavior.

#### E. Observability layer

The framework should include an integration transaction object or equivalent operational log that captures:

- source case,
- target incident,
- org,
- request type,
- transaction status,
- correlation id,
- retry count,
- last error,
- and event timestamp.

This becomes the operational backbone for monitoring, support diagnosis, and reprocessing.

## 8. Recommended Phased Approach

### Phase 1 — Foundation

- Architecture decision records.
- Use case register.
- Org inventory.
- Routing model definition.
- Field mapping inventory.
- Initial custom metadata model.
- Named Credential strategy.
- Logging and observability model.

### Phase 2 — MVP

- Salesforce intake UI.
- Metadata-driven request type behavior.
- Outbound Apex REST integration to ServiceNow.
- ServiceNow incident id stored on Case.
- Integration transaction logging.
- Optional administrative configuration screens as needed.

### Phase 3 — Operational Maturity

- Inbound update synchronization from ServiceNow to Salesforce.
- Retry and recovery tooling.
- Support dashboard and diagnostic views.
- Centralized visibility for Salesforce-related incidents.
- Packaging and deployment model for new-org rollout.

### Phase 4 — Enterprise Scale

- Rollout to additional Salesforce orgs.
- Richer catalog-driven intake experience.
- Standardized taxonomies and governance.
- Advanced reporting and analytics.
- Expanded enterprise support operating model.

## 9. Recommendation Summary

The recommended strategy is to build a reusable Salesforce ServiceNow Incident Framework rather than a narrow Case-to-Incident point solution. The strongest first release should focus on structured intake, metadata-driven routing, secure outbound incident creation, and transaction logging. Over time, the same framework can expand into bidirectional synchronization, richer templates, and broader multi-org adoption.

By separating stable integration logic from configurable business behavior, the solution will remain aligned to the current need while still accommodating UCLA Health’s expected process evolution.
