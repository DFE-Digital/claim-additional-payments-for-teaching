# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog]

## [Unreleased]

- Add started at and submitted at times to the admin view of a claim

## [Release 012] - 2019-09-30

- Add all-through schools to the eligible schools list
- Update privacy notice to include the collection of IP address
- Remove the admin claims CSV download

## [Release 011] - 2019-09-23

- Show how many claims are awaiting approval
- Show date of birth in a better place and format for claim checking
- Show DfE number against school in approver view of claim
- Drop redundant full_name column from claims table
- Updated Accessibility statement to show current issues

## [Release 010] - 2019-09-17

- Fix deployment template conflict
- Make closed schools ineligible for current school
- Exclude closed schools from current school search

## [Release 009] - 2019-09-17

- Add student loan plan and amount to approver view of a claim
- Link to Get Information About Schools from the admin view of a claim
- Monitor VSP availability
- Use slots to make VSP deployment zero-downtime
- Redirect `www.` to the base URL

## [Release 008] - 2019-09-12

- Fix broken middleware blocking `/admin` access

## [Release 007] - 2019-09-12

- Make content-security-policy more restrictive
- Use a fieldset for the gender question to improve accessibility
- Make "Continue" links appear as buttons to screen readers
- Fix missing assets for error pages
- Fix for allowing IPv6 addresses to visit the admin area

## [Release 006] - 2019-09-10

- Add ability for service operators to download data for payroll
- Allow service operators to approve claims
- Update school eligibility checkers to also check when a school closed
- Increase contrast on hint text to AAA standard
- Turned off autocomplete setting on National Insurance number and bank inputs
- Prefix titles with an error notification if an error is present
- Fix html validation issues with qts year and address views

## [Release 005] - 2019-09-10

- Redirect requests from any domain other than the canonical one
- Fix admin IP restriction bug due to port numbers
- Fix add clear and helpful page titles
- Fix a bug displaying incorrect number of decimal places on monetary number
  form fields
- Restrict access to `/admin` by IP
- Fix student_loan_start_date validation error message
- Fix OmniAuth failure path

## [Release 004] - 2019-09-04

- Fix claims export ordering
- Store claimants' names as separate fields
- Add ability to run data migrations
- Add data migration to back fill claimant's full name, middle name and surname
- Introduced rake tasks to export eligible schools to CSV

## [Release 003] - 2019-08-29

- Fixed a bug where missing "from" dates on Verify attributes caused a crash
- Stop user IP address appearing in Rollbar
- Redact all from dates in Verify response
- Fixed a bug where the no JS school contact was not selectable
- Fixed a bug in the GOVUK logotype svg src url
- Improve layout of closed schools in search results
- Add contact us page
- Fix an error in the claim CSV where the current school was displaying
  incorrectly
- Switch to using deployment slots for "zero-downtime" deployment

## [Release 002] - 2019-08-22

- Record Google Analytics page views immediately after the user accepts
- Update ineligibility page content for clarity
- Ignore unverified middle names from Verify response
- Report redacted GOV.UK Verify responses to help debug issues with our response
  handling
- Add static error pages for 400, 500 and 422 errors

## [Release 001] - 2019-08-21

- First release for student loan repayments private beta

[unreleased]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-012...HEAD
[release 012]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-011...release-12
[release 011]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-010...release-011
[release 010]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-009...release-010
[release 009]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-008...release-009
[release 008]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-007...release-008
[release 007]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-006...release-007
[release 006]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-005...release-006
[release 005]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-004...release-005
[release 004]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-003...release-004
[release 003]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-002...release-003
[release 002]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-001...release-002
[release 001]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/44b074c01db4b3dd1fcab1e3b73a521208a862ad...release-001
[keep a changelog]: https://keepachangelog.com/en/1.0.0/
