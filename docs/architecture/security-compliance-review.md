# Security and Healthcare Compliance Review

## Purpose
Describe system design, constraints, and non-functional architecture guidance.

## Audience
Architects, senior engineers, security reviewers, release leaders

## Scope
Target architecture, logical boundaries, and design quality concerns.

## Related Documents
- [Documentation Taxonomy Standard](documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

## Credential and transport security
- ServiceNow endpoint usage is constrained to Salesforce Named Credentials (`callout:<namedCredential>`).
- No secrets are stored in Apex code.

## Sensitive data handling
- Client and orchestration summaries are explicitly "safe summaries" and avoid raw PHI payload logging.
- Validation and transport errors are classified by category/code, reducing free-form sensitive stack leakage.

## Payload minimization
- Outbound payload validation enforces required fields and flags prohibited nulls before transport.
- Mapping-driven payload generation avoids uncontrolled field expansion.

## Access control and auditability
- Integration transaction and error objects remain the operational audit trail.
- Failure classification now includes pre-transport validation taxonomy for cleaner triage.

## Additional recommendations
1. Add field-level encryption policy review for any future patient-identifying custom fields.
2. Add SOC/ISS-aligned runbook for correlation-id tracing and incident response.
