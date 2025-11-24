# 12. Migration to Azure Kubernetes

Date: 2024-05-01

## Status

Accepted

## Context

DfE infrastruture is migrating to Azure Kubernetes Service (AKS). The old infrastucture which did not utilise infrastructure as code was setup by hand making it error prone and difficult to automate.

## Decision

Claim will be moving to AKS as old infrastructure will no longer be supported in the near future.

## Consequences

- Using terraform allows deployments to be configured in code which can be versioned
- Terraform allows for easy configuration of infrastructure which can be repeated across environments
- Review apps are now supported by DfE in-house infrastructure team giving increased support should any issues arise
- Review apps are now deployed to same infrastucture as production allowing testing to more accurately reflect the production environment arising to more realistic testing
