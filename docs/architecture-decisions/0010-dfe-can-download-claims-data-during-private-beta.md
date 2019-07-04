# 10. DfE can download claim data during private beta phase

Date: 2019-06-13

## Status

Accepted

## Context

DfE will need to verify claims to confirm eligibility before they can be
approved and paid. To help design and test the business process for checking and
verifying claims, the team will carry out a private beta where a limited set of
teachers will make real claims. The claims will be checked and processed
manually during the private beta, enabling the team to learn the best way to
build the tooling into the service that will aid more automated checking and
processing of claims.

## Decision

To give the team maximum flexibility to work with the claim data and design the
checks and processes during private beta, the service will include a secure
download of all the claim data held within the system.

This secure download will only be available during the private beta phase, and
will be removed before the service goes live for public beta.

## Consequences

The claims data stored in the service is high-value personal data, so strict
controls must be placed on who has access to the secure download.

Once the private beta phase ends, this functionality will need to be removed
from the service and any copies of the data destroyed
