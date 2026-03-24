# Access Model

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
