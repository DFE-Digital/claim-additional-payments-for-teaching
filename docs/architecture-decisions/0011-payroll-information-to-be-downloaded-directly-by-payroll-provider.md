# 11. Payroll information to be downloaded directly by payroll provider

Date: 2019-11-14

## Status

Accepted

## Context

Every month the service pays out approved claims as part of a payroll process
performed by a third party payroll provider. To perform this function the
payroll provider needs to be given the details of the claims and claimants. This
data is highly personal in nature and needs to be shared safely and securely
with the third-party provider.

## Decision

The payroll provider will download the monthly payroll data file directly from
the service’s back-office, which uses DfE's single sign-on service
[DfE Sign In](https://services.signin.education.gov.uk/) for authentication.

The payroll provider will be set up with their own organisation in DfE Sign In
so that they can manage their own user access and be responsible for
movers/leavers. Their users will only support a specific “Payroll operator”
role. This role will only allow the downloading of the monthly payroll file and
nothing else within the back-office.

The monthly payroll file will only be downloadable by the payroll provider’s
users. Other users will not be able to access the file.

The file will only be available as a one-time download; once downloaded, that
month’s file will no longer be available.

## Consequences

The payroll provider will be responsible for managing their own user access to
the monthly payroll file depending on their operational needs.

The payroll provider will need to take care when accessing the file as
re-downloading will not be possible without developer intervention to reset the
download.
