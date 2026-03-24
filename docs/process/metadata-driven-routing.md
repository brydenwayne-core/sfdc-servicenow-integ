# Process Flow: Metadata-Driven Routing

## Purpose
Formalize how routing and assignment are determined from metadata for each request type.

## Routing Resolution Flow

1. Identify active org configuration.
2. Identify applicable request type.
3. Evaluate active routing rules by precedence.
4. Resolve assignment target and fallback behavior.
5. Persist selected route keys in transaction telemetry.

## Decision Table Considerations

- Rule precedence and deterministic tie-breakers.
- Fallback-required policy for active request types.
- Effective-date and lifecycle-state filtering.

## Exception Paths

- No matching active rule and no fallback.
- Inactive/missing assignment target.
- Conflicting active rules with ambiguous precedence.

## Measurable Controls

- Route resolution success rate by org/request type.
- Count of fallback route invocations.
- Count of ambiguous or invalid routing configurations detected pre-release.

## Cross-links

- [Metadata Architecture](../architecture/metadata-architecture.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
- [Failure Classification Flow](failure-classification-and-triage.md)
