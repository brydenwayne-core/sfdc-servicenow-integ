# Test Architecture

## Overview
The package test strategy is organized into four layers:
1. **Metadata simulation** via `TestDataFactory` and `MockConfigProvider`.
2. **Domain factories** via `TestCaseFactory` and `TestIntegrationFactory`.
3. **Scenario builders** via `TestScenarioFactory` for intent-based setup.
4. **Transport mocks** via `MockServiceNowHttpResponse`, `MockServiceNowErrorResponse`, and `MockTimeoutResponse`.

## Reuse Pattern
- `IntegrationTestUtils.applyBaselineMetadata()` is the default bootstrap.
- Scenario tests should construct `SN_IntegrationOrchestrator.RequestContext` through helper utilities.
- Client tests must assert healthcare-safe summaries rather than raw payload fragments.

## Negative Coverage Standard
At minimum, each service must include tests for:
- configuration missing/inactive,
- transport timeout and retryability,
- malformed or incomplete payloads,
- unsupported request type paths.

## Naming Conventions
- Unit tests: `<ClassUnderTest>Test`.
- Mock types: `Mock<Dependency><Behavior>`.
- Scenario builders: `create<OrgOrFlow><Condition>()`.

## Metadata-driven QA
The metadata bundle in `TestDataFactory.createBaselineMetadata()` remains the contract fixture.
Tests should prefer changing metadata in memory over creating ad-hoc production-like records.
