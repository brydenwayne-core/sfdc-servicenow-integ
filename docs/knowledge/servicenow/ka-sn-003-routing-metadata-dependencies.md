# KA-SN-003 How Routing Metadata Affects Incident Creation

## Purpose
Explain how Salesforce routing metadata decisions impact ServiceNow incident outcomes.

## Audience
ServiceNow admins, integration owners, and support coordinators.

## Scope
Dependency mapping between Salesforce request type metadata and ServiceNow assignment behavior.

## Source of Truth
- [Metadata-Driven Routing](../../process/metadata-driven-routing.md)
- [Field Ownership Matrix](../../process/field-ownership-matrix.md)
- [Admin Management Handbook](../../admin/admin-management-handbook.md)

## Key Dependencies
- Request type determines routing rule selection.
- Routing metadata controls assignment group and taxonomy values.
- Field ownership governs which system can authoritatively set each mapped field.

## Failure Indicators
- Incidents created with incorrect assignment group.
- Category/subcategory values rejected or defaulted unexpectedly.
- Repeat incidents for same request type show inconsistent routing.

## Support Actions
1. Validate request type and deployed routing metadata version.
2. Confirm ServiceNow target values are still valid.
3. Coordinate metadata correction and controlled replay.
