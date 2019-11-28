# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog]

## [Unreleased]

- Redesign the layout of the payment confirmation email
- Add script to get a console on a container instance
- Stop running workers in the same instance as the web app
- Show policy next to claims in admin view
- Allow admins to filter list of claims by policy
- Update Maths & Physics sequence with new ITT specialism questions
- Adjust Maths & Physics private beta start page content
- Correct wording in Maths & Physics claim emails
- Remove explicit mention of Student Loans policy on accessibility statement
- Update re-apply date on performance/disciplinary ineligibility pages
- Increase the claim checking deadline date to 12 weeks
- Privacy notice wording works for Maths & Physics
- A teacher can submit a Maths and Physics claim

## [Release 036] - 2019-11-26

- Hardcode VSP entity ID to fix our GOV.UK Verify journey
- Temporarily whitelist new DfE Manchester office IP so that service operators
  can continue to access admin interface

## [Release 035] - 2019-11-25

- Make www.claim-additional-teaching-payment.service.gov.uk the canonical domain
- Admin users are redirected to their original request path after sign in

## [Release 034] - 2019-11-25

- Change wording of the student loan start date question for more than more
  course
- Add the eligibility questions for the Maths and Physics journey
- Show a different feedback URL depending on the policy being used
- Maths & Physics claims will work with the payroll process
- Start using the GOV.UK service domain

## [Release 033] - 2019-11-21

- Display the gross pay instead of the gross value in the payment confirmation
  email
- Update transactional emails with improved content
- Clear claim session before view path gets calculated
- Add some copy to make it clear why we ask about a user's student loan
- Update transactional emails to support the two different policy types
- Change "computer science" to "computing" on student loans questions

## [Release 032] - 2019-11-19

- Update employment-related copy to clarify that the policy cares about the
  location that the teacher _taught_ at, not where their employer is based.
- A service operator can open or close an individual service from the admin
  interface. Closing the service prevents users from making claims. As part of
  this, we remove the global maintenance mode, and the default maintenance mode
  availability message.
- Service operators are shown when the next payroll run file is due to be sent
  to Cantium
- Only allow payroll runs to be created if none exist already for the current
  month
- Added post-eligibility questions to the Maths & Physics journey
- Add the current school question to the maths and physics claim journey

## [Release 031] - 2019-11-18

- Introduce the beginnings of the Maths & Physics journey, protected with basic
  auth
- Send statistics on submitted claims to Geckoboard
- A service operator can create and download a Database of qualified teachers
  (DQT) report request csv file

## [Release 030] - 2019-11-12

- Add policy specific "Reply-to" address for claim emails
- Upgrade to Rails 6.0.1

## [Release 029] - 2019-11-07

- Make admin claim search case insensitive
- Change all of the existing claims' National Insurance numbers to upper case
- Add a link to our service's satisfaction survey to the confirmation page
- Improve journey for users that worked at more than one school during the claim
  period

## [Release 028] - 2019-11-06

- Always save claimant's National Insurance number in upper case
- When checking whether a claim's details have been used in other claims, ignore
  the case (i.e. capitalisation) of the claims' details

## [Release 027] - 2019-11-05

- Fixed bug in claim matcher code that would match blank building society roll
  numbers
- Admin users are sent to the sign in page when their session times out
- Add noindex and nofollow directives to prevent search engines indexing pages

## [Release 026] - 2019-11-04

- A clear warning is shown to service operators when a claim contains details
  that have been used in other claims. The other claims are listed and linked

## [Release 025] - 2019-10-31

- Adjusted ineligibility screens for users who may have taught at more than one
  school
- Allow user to restart their claim by visiting start page

## [Release 024] - 2019-10-31

- Updated feedback URL ready for public beta
- Service updated to be linked to from external start page
- Update the Verify Service Provider to version 2.1.0
- Make static pages such as "Cookies", and "Contact us" policy aware

## [Release 023] - 2019-10-29

- Update copy to make it clear we may deduct a student loan repayment from
  amount the claimant receives
- Inform the user that their claim is ineligible, if the school that they are
  currently employed at is not eligible
- Claimants recieve payment notifications once a payroll run has been processed

## [Release 022] - 2019-10-24

- The Payment Confirmation Report for a payroll run can be uploaded and
  processed
- Update student loan question to latest version
- Allow service operators to search for a claim
- No longer ask for specific year for QTS award year

## [Release 021] - 2019-10-22

- Service operators can add notes when they approve or reject a claim

## [Release 020] - 2019-10-21

- Service operators can easily identify claims that are close to their deadline

## [Release 019] - 2019-10-17

- Put the service into "permanent" maintenance mode until public beta
- Updated maintenance page content to better fit the service
- Payroll export start date is the second Monday of the month and the end date
  is the following Sunday

## [Release 018] - 2019-10-16

- Run schema and data migrations at the same time
- Exclude /admin from maintenance mode
- Allow service to be put into maintenance mode

## [Release 017] - 2019-10-10

- Improve bank account capture with separate account name and roll number for
  building society accounts
- Remove the legacy payroll CSV download feature
- A service operator can create a payroll run and download a CSV file for
  submission to Cantium
- A service operator can see if a claim is missing a payroll gender

## [Release 016] - 2019-10-08

- Admin uses its own layout with with updated navigation
- A service operator can reject a claim and an email is sent to the claimant
- Make sure claimants cannot make a claim of £0

## [Release 015] - 2019-10-07

- Update the first page of the claim to initialise, rather than create a claim
- Rework URL structure in preparation for Maths & Physics policy
- Changes to accessibility statement as we think we now meet AA standard

## [Release 014] - 2019-10-03

- Reword the question about how many courses the user studied
- Update Cantium CSV fields

## [Release 013] - 2019-10-01

- Updated accessible-autocomplete to 2.0.0
- Use a Check model to record the status of a claim
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
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-036...HEAD
[release 036]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-035...release-036
[release 035]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-034...release-035
[release 034]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-033...release-034
[release 033]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-032...release-033
[release 032]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-031...release-032
[release 031]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-030...release-031
[release 030]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-029...release-030
[release 029]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-028...release-029
[release 028]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-027...release-028
[release 027]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-026...release-027
[release 026]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-025...release-026
[release 025]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-024...release-025
[release 024]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-023...release-024
[release 023]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-022...release-023
[release 022]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-021...release-022
[release 021]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-020...release-021
[release 020]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-019...release-020
[release 019]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-018...release-019
[release 018]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-017...release-018
[release 017]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-016...release-017
[release 016]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-015...release-016
[release 015]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-014...release-015
[release 014]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-013...release-014
[release 013]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-012...release-013
[release 012]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-011...release-012
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
