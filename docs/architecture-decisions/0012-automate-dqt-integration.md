# 12. Automate DQT Integration with Claim service

Date: 2021-03-19

## Status

Accepted

## Context

DfE needs to validate the teacher's identity and qualification before approving
the claim.

GOVUK Verify is being depreciated ((ADR
No. 0008)[https://github.com/DFE-Digital/claim-additional-payments-for-teaching/blob/master/docs/architecture-decisions/0008-use-govuk-verify-for-claiment-identity-assurance.md])
and is being replaced with integration DqT to validate teacher's identity.

## Decision

The service will replace GOV verify with Database for Qualified Teachers
([DQT](https://teacherservices.education.gov.uk/SelfService/Login)) for
teacher's identity and QTS check before approving the claims.

DQT will provide a DQT dataset according to the policy on a daily basis and the
service will validate the teacher's identity and QTS against the DQT via API.

The claim service team will be responsible to manage the temporary DQT API and
data until actual DQT API ready to server all requests.

This DQT integration automation will also replace the manually verify claims
through DQT CSV report.

## Consequences

The claim service team needs to ensure that DQT dataset is protected and only
accessible via protected API.

The team must replace the temporary DQT API whenever actual DQT API will be
ready to serve requests and the claim team must delete the DQT dataset and
destroy temporary DQT API.

The service operator will manually validate the teacher's identity and QTS
checks if the DQT automation process fails.
