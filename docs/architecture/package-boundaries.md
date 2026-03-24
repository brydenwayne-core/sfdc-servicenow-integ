# Package Boundaries

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

## Purpose

This repository is structured as a reusable Salesforce-to-ServiceNow product with explicit package boundaries so teams can install the runtime, configuration model, admin console, and sample metadata independently.

The package split is designed to support four goals:

1. keep the integration runtime reusable across orgs,
2. separate configuration schema from sample org data,
3. keep admin/support artifacts out of the runtime package, and
4. make future unlocked-package promotion and org rollout simpler.

## Revised package layout

```text
force-app/
  core/
    main/default/           # runtime framework: Apex, runtime objects, async services
  config/
    main/default/           # configuration schema + secure connection metadata
  admin/
    main/default/           # operational/admin UX artifacts
  sample-config/
    main/default/           # example custom metadata records for reference orgs
```

## Package responsibilities

### 1. `force-app/core` — runtime framework package

This package now contains only runtime assets that the integration executes against in every org:

- Apex orchestration and service classes,
- runtime custom objects such as transaction/error/link records,
- queueables, test factories, and supporting framework code.

This package should remain free of org-specific sample records and free of admin-console-only metadata.

### 2. `force-app/config` — configuration base package

This package contains the metadata that defines how orgs configure the framework without embedding org-specific records:

- Custom Metadata Type definitions such as `SN_Org_Config__mdt`, `SN_Request_Type__mdt`, `SN_Field_Mapping__mdt`, and routing/assignment types,
- Named Credential and External Credential metadata used by the runtime.

This split makes the configuration contract explicit. Teams can promote the schema and secure transport layer once, then add environment-specific records separately.

### 3. `force-app/admin` — operational/admin package

This package contains metadata used by support and release teams rather than by the runtime itself:

- admin Lightning app shell,
- tabs,
- page layouts,
- permission sets.

These artifacts are installable where needed, but they do not need to be bundled into the runtime package. That keeps the runtime lean and lets future admin-console evolution move independently.

### 4. `force-app/sample-config` — sample org configuration package

This package contains example `customMetadata` records only.

These records demonstrate how an implementation team can stand up a new org, but they are intentionally not the canonical production source of truth. Teams can deploy this package into sandboxes for learning, clone records into an implementation-specific repo, or use it as rollout scaffolding.

## Boundary rules

### Core vs config

- Put executable framework behavior in `core`.
- Put configuration schema and secure connection metadata in `config`.
- Do not place sample `customMetadata` records in either package.

### Runtime vs admin

- Put metadata required for transactions to execute in `core` or `config`.
- Put support-console, operator, and admin UX artifacts in `admin`.
- Admin artifacts may depend on runtime objects, but runtime code must not depend on admin UX metadata.

### Product vs sample org content

- Productized, reusable metadata belongs in `core`, `config`, or `admin`.
- Example org records belong in `sample-config` only.
- Customer- or environment-specific production records should eventually live outside this repo or in a dedicated implementation layer.

## Unlocked-package install order

The repo is now shaped for a clearer unlocked-package lifecycle:

1. `SN_Integration_Config_Base`
2. `SN_Integration_Core_Runtime`
3. `SN_Integration_Admin`
4. `SN_Integration_Sample_Config` (optional, non-production/reference use)

This ordering reflects dependency direction:

- the configuration base establishes the metadata contract and secure endpoint definitions used by the rest of the product,
- the runtime then layers executable services and runtime data objects on top of that contract,
- the admin package layers on operational UX,
- and the sample package provides illustrative records on top of the configuration schema.

## Org rollout guidance

For a new org rollout, the preferred sequence is:

1. install/deploy `config`,
2. install/deploy `core`,
3. configure credentials and verify endpoint connectivity,
4. optionally install `admin` for support users,
5. optionally deploy `sample-config` into lower environments as a starting template,
6. replace sample records with approved org-specific records before production use.

This makes it easier to keep reusable product metadata stable while allowing each org to own its implementation-specific records and release cadence.

## Why this is better

Compared with the prior three-way split, this structure makes package intent more explicit:

- configuration schema is no longer mixed into the runtime package,
- admin/support metadata is clearly separated from transaction execution concerns,
- sample records remain isolated from reusable product metadata,
- and package dependency direction now mirrors how enterprise teams usually promote metadata through environments.

That combination makes the repository read more like a reusable enterprise product and less like a single implementation snapshot.
