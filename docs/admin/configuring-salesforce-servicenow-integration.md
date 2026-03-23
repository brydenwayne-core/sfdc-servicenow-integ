# Salesforce to ServiceNow Integration Admin Guide

## Purpose

This guide explains how Salesforce administrators configure and maintain the metadata-driven Salesforce to ServiceNow integration framework. It is intended for platform admins, release managers, and implementation teams onboarding new orgs or modifying request behavior.

## Configuration Model Overview

The framework is driven by deployable metadata and secure connection assets rather than hardcoded Apex logic.

Core configuration assets:

- `SN_Org_Config__mdt`: defines the Salesforce org context, default request type, endpoint key, business unit, and activation state.
- `SN_Request_Type__mdt`: defines which request types are available for an org and which routing/template behavior they use.
- `SN_Field_Mapping__mdt`: maps Salesforce source data into the outbound ServiceNow incident payload.
- `SN_Routing_Rule__mdt`: determines assignment behavior and routing outcomes.
- `SN_Assignment_Target__mdt`: defines the ServiceNow assignment group/user/queue references used by routing.
- `SN_Feature_Toggle__mdt`: enables or disables optional behavior by org.
- `SN_Endpoint_Config__mdt`: points the org configuration to the correct Named Credential and ServiceNow API base path.
- Named Credential and External Credential metadata: provide secure transport/authentication.

## Before You Start

Before changing configuration, confirm the following:

- the target Salesforce package version is deployed in the environment,
- the Named Credential and External Credential are valid,
- the ServiceNow team has provided the correct endpoint, assignment IDs, and field expectations,
- required request types and routing decisions are approved,
- and change control is in place for production metadata updates.

## How to Add a New Org

### Step 1: Create or update endpoint configuration

Create an `SN_Endpoint_Config__mdt` record if the org needs a new endpoint key.

Recommended values to confirm:

- endpoint config key,
- Named Credential name,
- base path,
- timeout,
- active status.

Use an existing pattern such as the sample configuration records under `force-app/sample-config/main/default/customMetadata/` as a baseline.

### Step 2: Add the org metadata record

Create a new `SN_Org_Config__mdt` record with at least:

- **Org Key**: stable key used throughout metadata.
- **Salesforce Org Id**: identifier for reporting and support correlation.
- **Business Unit**: support/reporting context.
- **Environment**: sandbox, test, production, etc.
- **Default Request Type**: fallback request type when one is not explicitly supplied.
- **Endpoint Config Key**: references `SN_Endpoint_Config__mdt`.
- **Is Active**: enables the org for processing.

### Step 3: Add request types for the org

For each supported request flow, create one or more `SN_Request_Type__mdt` records scoped to the org.

Minimum values:

- request type key,
- org key,
- source object,
- operation mode,
- incident template key,
- routing key,
- active state.

### Step 4: Add assignment targets

Create `SN_Assignment_Target__mdt` records for each ServiceNow assignment group, user, or queue the org can route to.

Capture:

- assignment target key,
- org key,
- assignment type,
- external assignment id from ServiceNow,
- display name,
- active state.

### Step 5: Add routing rules

Create `SN_Routing_Rule__mdt` records that map request types and business conditions to assignment targets and optional routing behavior.

At minimum, define:

- org key,
- request type key,
- assignment target key,
- priority,
- default/fallback flag,
- active state,
- JSON `Match_Criteria__c` payload.

Every active request type should have a safe default route unless the business process intentionally blocks submission.

### Step 6: Add field mappings

Create `SN_Field_Mapping__mdt` records for the request type.

Recommended minimum mappings:

- short description,
- description,
- category/subcategory when required,
- any org identifier or request type identifier required by ServiceNow,
- assignment group only when routing does not inject it separately.

### Step 7: Enable feature toggles

Create or update `SN_Feature_Toggle__mdt` for org-specific capabilities such as:

- case-to-incident sync,
- comment sync,
- file sync,
- future phased rollouts.

### Step 8: Deploy and validate

After deployment:

- submit a test Case,
- verify an `Integration_Transaction__c` record is created,
- verify the transaction reaches `Succeeded`,
- confirm the related `ServiceNow_Incident_Link__c` record is populated,
- confirm no sensitive payload body is written to log summaries.

## How to Enable a New Request Type

When enabling a request type for an existing org:

1. Create or activate the `SN_Request_Type__mdt` record.
2. Confirm the incident template key and routing key are correct.
3. Add all required `SN_Field_Mapping__mdt` records.
4. Add or update `SN_Routing_Rule__mdt` records.
5. Confirm assignment targets exist and are active.
6. Confirm any feature toggles required for that flow are enabled.
7. Validate with a representative Case submission.

## How to Maintain Field Mappings

### Mapping rules

Field mappings should remain minimal, explicit, and metadata-driven.

Use the following principles:

- prefer one mapping record per target field,
- keep sequence values stable and readable,
- use org-scoped mappings only when behavior truly differs,
- use global mappings for shared behavior,
- avoid encoding business decisions in transforms if routing or request type metadata is the better source.

### Common transform patterns

Supported patterns in the framework include:

- direct field copy,
- static value,
- uppercase/lowercase/trim transforms,
- org key injection,
- request type key injection.

### Change process

When changing mappings:

1. identify the request type and org scope,
2. confirm the ServiceNow target field API name,
3. deploy the metadata change,
4. submit a validation Case,
5. review the transaction result and resulting ServiceNow incident.

## How to Update Routing Rules

Routing rules are evaluated by org and request type.

Recommended approach:

1. confirm the assignment target exists,
2. define the matching conditions in JSON,
3. set the rule priority,
4. decide whether the rule is default,
5. include only routing behavior that belongs in metadata, such as assignment target overrides, template overrides, or sync flags.

### Routing design tips

- keep one default rule per active request type when possible,
- use specific rules for high-confidence branches,
- avoid overlapping criteria that would create ambiguous matches,
- coordinate assignment target changes with the ServiceNow team.

## How to Activate Feature Toggles

Use `SN_Feature_Toggle__mdt` to phase behavior on or off by org.

Recommended admin practice:

- define a consistent feature key taxonomy,
- use global defaults only for behavior that is safe in all orgs,
- override at the org level only when rollout needs to differ,
- document why a toggle was enabled or disabled.

Examples:

- enable `CASE_TO_INCIDENT_SYNC` before go-live,
- enable `COMMENT_SYNC` only after the comment process is validated,
- disable a noncritical sync feature temporarily during incident response.

## Troubleshooting Failed Transactions

### Where to look first

Start with these records in Salesforce:

1. `Integration_Transaction__c`
2. `Integration_Error__c` or `SN_Integration_Error__c` if implemented in the environment
3. `ServiceNow_Incident_Link__c`
4. relevant metadata records for org, request type, routing, mapping, and toggles

### Troubleshooting sequence

#### 1. Confirm the transaction status

Check:

- status,
- retry count,
- correlation ID,
- request type,
- org code,
- error category,
- error code,
- safe request/response summaries.

#### 2. Identify the failure category

Common categories:

- **Configuration**: missing org config, endpoint config, inactive request type, missing assignment target.
- **Validation**: required fields missing, routing mismatch, ServiceNow 4xx validation errors.
- **Transport**: timeout, 5xx, network unavailability, callout failure.
- **Security**: authentication/authorization problems.

#### 3. Check metadata alignment

Review whether:

- the org is active,
- the request type is active,
- the endpoint config key is valid,
- required field mappings exist,
- the routing rule can resolve an assignment target,
- required toggles are enabled.

#### 4. Decide on the recovery path

- **Correct data/configuration then retry** for mapping, routing, or inactive configuration issues.
- **Retry later** for transient transport issues.
- **Escalate immediately** for auth/security problems or duplicate-incident uncertainty.

## Administrative Change Checklist

Before promoting metadata changes:

- validate the org key and request type key naming,
- verify default routes exist,
- verify all referenced assignment target keys exist,
- verify field mappings cover required ServiceNow fields,
- verify feature toggles reflect the intended rollout,
- verify support documentation is updated.

## Recommended Documentation to Keep Current

Admins should maintain:

- org onboarding notes,
- request type catalog,
- routing decision matrix,
- field ownership/mapping matrix,
- feature toggle inventory,
- support contact list and escalation path.
