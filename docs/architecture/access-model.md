# Access Model

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

## Personas
1. **Runtime User**: launches business workflow that triggers orchestration.
2. **Integration Operator**: monitors runs and reprocesses failed transactions.
3. **Integration Admin**: manages metadata configuration and advanced tools.
4. **Support Analyst**: read-only access for troubleshooting.

## Permission set posture
- `SN_Integration_Operator`: operational object read/edit access for run-state management.
- `SN_Integration_Admin`: full config and operational administration.
- `SN_Integration_Support`: read-only access to transaction/link/error data for least-privilege support triage.

## Separation of responsibilities
- Configuration metadata management is reserved for admins.
- Day-to-day replay and execution monitoring is separated for operators.
- Troubleshooting visibility is available without mutation rights for support users.
