# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog]

## [Unreleased]

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
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-005...HEAD
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
