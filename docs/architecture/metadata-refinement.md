# Metadata Refinement Summary

## Purpose

This document summarizes the metadata-model refinements made to improve long-term maintainability and admin usability for the Salesforce-to-ServiceNow integration package.

The intent is to let business process maturity evolve without forcing repeated Apex rewrites.

## Key refinements

### 1. Standard lifecycle and documentation fields across configuration metadata

The core configuration Custom Metadata Types now use a more consistent admin contract by adding shared governance fields such as:

- `Lifecycle_Status__c`
- `Effective_Start_Date__c`
- `Effective_End_Date__c`
- `Admin_Notes__c`
- `Documentation_URL__c`

Where ownership is especially important, records also now include `Owner_Team__c`.

This makes it easier to:

- stage draft metadata before activation,
- deprecate records without immediately deleting them,
- preserve audit-friendly admin guidance,
- and document when a record should or should not be used.

### 2. Clearer ordering semantics

Ordering fields were clarified so future admins can reason about precedence without reading code:

- `SN_Field_Mapping__mdt.Sequence__c` is now labeled as execution order.
- `SN_Routing_Rule__mdt.Priority__c` is now labeled and documented as evaluation priority.
- `SN_Request_Type__mdt` now includes `Priority__c` so admins have a stable sort/order field when multiple active request types exist for the same org.

The design expectation is:

- lower numbers mean higher precedence,
- specific rules should evaluate before fallback rules,
- and gaps in numbering are acceptable to reduce churn when inserting new records later.

### 3. Safer fallback behavior for routing

Fallback routing is now documented more explicitly:

- `SN_Routing_Rule__mdt.Is_Default__c` is labeled as a fallback rule,
- descriptions now clarify that fallback rules should be evaluated after more specific active rules,
- and sample metadata now includes one active fallback routing rule per sample request type.

This creates a stronger contract for future routing logic and lowers the risk of ambiguous “default” behavior.

### 4. Deprecation-ready request types

`SN_Request_Type__mdt` now includes `Replacement_Request_Type_Key__c` so teams can mark a request type as deprecated while pointing admins toward the intended successor.

Combined with `Lifecycle_Status__c`, this supports controlled change instead of destructive replacement.

### 5. Sample metadata now reflects complete configuration chains

The sample package was expanded so referenced records exist for the sample scenarios:

- incident templates were added for each sample request type,
- fallback routing rules were added for each sample request type,
- and feature toggle examples were added for global and org-specific rollout patterns.

This makes the sample package more useful as an org rollout reference and reduces ambiguity for admins copying patterns into implementation-specific repos.

## Admin usability patterns introduced

### Documentation-oriented fields

Admin-facing notes and documentation links were added so setup records can explain:

- business intent,
- rollout caveats,
- ownership,
- and supporting runbooks.

That helps keep critical operational context close to the metadata itself.

### Lifecycle-aware maintenance

Effective dates and lifecycle fields allow admins to prepare future changes ahead of time instead of replacing records at the moment of cutover.

This is especially valuable for:

- routing changes,
- phased feature rollouts,
- request type transitions,
- and org onboarding waves.

## Lightweight validation / guardrails

A new script, `scripts/ci/validate-config-metadata.py`, validates the sample metadata for common structural issues before runtime, including:

- missing referenced request types,
- missing assignment targets,
- missing incident templates,
- missing endpoint configs,
- duplicate active fallback routing rules,
- duplicate field-mapping execution orders within the same scope,
- and invalid effective-date ranges.

This is intentionally lightweight, but it provides an early warning system for admin mistakes that would otherwise surface only during execution.

## Operational recommendations

When extending the metadata model further, prefer the following practices:

1. add fields that describe intent and lifecycle before adding code branches,
2. use stable keys and replacement-key fields instead of renaming records in place,
3. treat fallback routing as a deliberate design decision, not an accidental default,
4. keep sample records illustrative and complete enough to validate relationships,
5. and add validation checks whenever a new metadata dependency is introduced.

These refinements are intended to keep the configuration model adaptable as more orgs, workflows, and rollout phases are introduced.
