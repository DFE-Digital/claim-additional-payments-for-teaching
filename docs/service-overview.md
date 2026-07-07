# Service overview: teacher retention and incentive payments

## Purpose

This service supports the Department for Education's (DfE) strategic
commitment to improving teacher recruitment and retention, particularly in
high-demand subjects and regions. It delivers financial incentives to eligible
teachers through a streamlined digital service.

## How the service works

1. Application submission: teachers apply online.
2. Eligibility verification: operations team checks claims against policy
   criteria in the admin site.
3. Outcome notification: applicants are informed of the result.
4. Payment processing: approved payments are made directly to bank accounts.

## Development user journeys

Each pull request with the "deploy" label applied creates a review app containing only that change. The review app URL is posted as a comment on the pull request.

Review app basic auth credentials:

- Request these from a developer on the team, or retrieve them from Azure Key Vault.

## GOV.UK One Login

One Login integration testing is currently available in the test environment. It is not available in review apps. This applies to the Further Education and Early Years user journeys.

When the One Login flow begins, users are redirected to
https://integration.account.gov.uk/.

Integration endpoint basic auth credentials:

- Request these from a developer on the team, or retrieve them from Azure Key
  Vault.

## Test environment user journeys

- Admin: https://test.claim-additional-teaching-payment.service.gov.uk/admin
- Additional payments:
  https://test.claim-additional-teaching-payment.service.gov.uk/additional-payments/landing-page
- Student loans:
  https://test.claim-additional-teaching-payment.service.gov.uk/student-loans/landing-page
- FE claimant:
  https://test.claim-additional-teaching-payment.service.gov.uk/further-education-payments/landing-page
- Early years:
  https://test.claim-additional-teaching-payment.service.gov.uk/early-years-payment/guidance
- EYTRP:
  https://test.claim-additional-teaching-payment.service.gov.uk/early-years-teachers-recognition-payments/landing-page

## Production environment user journeys

- Admin: https://www.claim-additional-teaching-payment.service.gov.uk/admin
- Additional payments:
  https://www.claim-additional-teaching-payment.service.gov.uk/additional-payments/landing-page
- Student loans:
  https://www.claim-additional-teaching-payment.service.gov.uk/student-loans/landing-page
- Early years (provider):
  https://www.claim-additional-teaching-payment.service.gov.uk/early-years-payment/guidance
- Early years (practitioner):
  https://www.claim-additional-teaching-payment.service.gov.uk/early-years-payment-practitioner/find-reference?skip_landing_page=true
- EYTRP:
  https://www.claim-additional-teaching-payment.service.gov.uk/early-years-teachers-recognition-payments/landing-page
