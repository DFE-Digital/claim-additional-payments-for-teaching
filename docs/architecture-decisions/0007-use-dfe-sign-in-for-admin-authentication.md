# 7. Use DfE Sign In for admin authentication

Date: 2019-05-28

## Status

Accepted

## Context

We want to authenticate DfE staff members so they can access an admin area of
the service for checking and processing claims.

## Decision

We will use DfE's single sign-on service
[DfE Sign In](https://services.signin.education.gov.uk/) and authenticate
through OpenID Connect.

## Consequences

DfE Sign In accounts can only be created by a small number of 'approvers' in
DfE.

Developers will be required to run development with https as DfE Sign In
requires it. They can bypass the DfE Sign In integration by omitting the
relevant environment variables when running the app in development.
