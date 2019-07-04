# 11. Make payments using DfE's existing finance system: NAV

Date: 2019-XX-XX

## Status

Draft

## Context

The service needs to make net-of-tax payments directly to teachers that have
made successful claims (i.e. net of tax, national insurance and student loan
recoveries). Doing this requires two things:

1. to operate PAYE as a "supplementary employer" so that DfE can pay any tax, NI
   and student loan recoveries due on the teachers’ behalf, and report the
   payments to HMRC
2. to make BACS payments directly to teachers’ bank accounts for the net amount

A number of options for doing these things were considered during the project’s
alpha phase, including several existing internal systems that are already used
by DfE for making payments and operating payroll/PAYE. Ultimately all the
existing systems were deemed not suitable, and the [advice for the beta phase]
was to source an all-in-one payment solution to perform the above.

The beta team re-visited this decision, partly because an all-in-one solution to
do these things doesn’t exist on the Digital Marketplace, and because it would
be difficult to procure a system through open tender in time to meet the
project’s deadlines.

## Decision

The service will use the DfE's existing funding and financial system (NAV) to
make payments to teachers. This will be made possible with the upgraded version
(Microsoft Dynamics Business Central), which is due to come online in August.
The upgraded version will have an employee payroll and expenses module
available, which will make it possible to register teachers in the system as
"employees" and make direct payments to their bank accounts.

## Consequences

The team will need to collaborate with the FSIP team in Coventry to integrate
the service with NAV such that teachers can be set up in NAV and payments made
to their bank accounts via BACS.

Because the payments will be made using the existing DfE finance systems and
processes, the accounting and reporting for these payments will come for free.

The employee payroll and expenses module within NAV doesn't perform the
calculations for the tax/NI/SLR that is due on the payments. This will either
have to be done by the service itself, or as a bespoke add-on to NAV provided by
FSIP’s supplier partner.

The employee payroll and expenses module within NAV doesn't support the
reporting aspect of running payroll (RTI). The team is currently working with
the FSIP team to explore whether this capability can be built into NAV, or
whether an alternative mechanism for performing RTI will be required.

[advice for the beta phase]:
  https://drive.google.com/drive/u/2/folders/1xnbNliEbDNya2HNexS6b05oF5WG7le59
