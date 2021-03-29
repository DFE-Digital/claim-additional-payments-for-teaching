# 8. Use GOVUK Verify for claimant identity assurance

Date: 2021-03-19

## Status

Deprecated (Replaced by ADR #0012)

## Context

We need to be confident that a claimant is who they say they are to ensure
payments are made to eligible claimants only and to minimise fraudulent claims.

## Decision

We will integrate with the [GOVUK Verify](https://www.verify.service.gov.uk/)
service, a ‘secure way to prove who you are online’.

GOVUK Verify recommend any services that ‘gives users money or benefits’ use
‘Level of Assurance 2’ or ‘LOA2’, we will follow this guidance.

[Understand Level of Assurance](https://www.verify.service.gov.uk/understand-levels-of-assurance/)

## Consequences

Using GOVUK Verify requires DfE to sign GOVUK Verify’s agreements.

Integrating with GOVUK Verify requires the hosting and management of a ‘Verify
Service Provider’ or VSP. DfE only needs a single VSP to integrate GOVUK Verify
with any number of services, including ours.

There will be on-going management of the VSP including security key rotation on
a regular basis.

Adding LOA2 verification to our user journey increases the time and difficulty
for a claimant to complete an application.
