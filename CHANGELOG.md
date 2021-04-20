# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog]

## [Unreleased]

- Remove GOVUK Verify IAS components
- Remove GOVUK Verify from claimant journeys
- Documentation updates - DFE Signin process
- Reduce sensitivity of high response time alert
- Build new Early Career Payments Policy
- Build new Early Career Payments Journey with following page additions
  - Eligibility Journey
    - Add 'Did you do your NQT the academic year after your ITT?'

## [Release 089] - 2021-03-05

- Infrastructure changes

## [Release 088] - 2021-01-27

- Add an additional rejection reason to the claim rejection email (Zendesk
  #13584)

## [Release 087] - 2020-11-02

- Update the DQT automation to include HECOS codes as well as JACS codes
- Update email copy for claim submitted and claim approved
- Fix incorrect display of claims in payroll run
- Update Verify Service Provider to version 2.2.0

## [Release 086] - 2020-10-08

- Fix incorrect summing for claims by policy

## [Release 085] - 2020-10-07

- Update payment email copy
- Seperate policies in payment with a space

## [Release 084] - 2020-09-30

- Update data report request to retrieve email address and date of birth

## [Release 083] - 2020-09-25

- Geckoboard now only includes claims from the current academic year

## [Release 082] - 2020-09-02

- Break down number of claims and claim amount in payroll runs by policy
- Display the correct financial year for employment as part of the employment
  task.

## [Release 081] - 2020-09-01

- Changes made to content pages ready for academic year 2020-21
- Increase Verify timeout from 90 minutes to 120 minutes
- Update code formatting to match latest Standard version

## [Release 080] - 2020-06-25

- Bump rails from 6.0.3.1 to 6.0.3.2

## [Release 079] - 2020-06-25

- Add contextual information when incorrect data is in a confirmation report
- Remove thousand seperators from numeric columns in confirmation reports

## [Release 078] - 2020-06-22

- Remove banking_name when scrubbing personal data from a claim

## [Release 077] - 2020-06-18

- When removing personal data from claims, don’t treat a claim as rejected if
  the rejection has been undone

## [Release 076] - 2020-06-16

- Security updates

## [Release 075] - 2020-05-11

- A service operator isn’t allowed to amend student loan plan when the claimant
  has already paid off their student loan

## [Release 074] - 2020-04-07

- Display payroll status of claim within task view
- Display claim amount within task view

## [Release 073] - 2020-04-07

- Move shipping logs to logstash to Filebeat
- Remove a negative contraction in some text, to follow GOV.UK style guide

## [Release 072] - 2020-04-03

- DQT report upload now performs automated identity confirmation checks

## [Release 071] - 2020-04-03

- The identity confirmation task is now present on all submitted claims

## [Release 070] - 2020-04-03

- Add secondary SAML encryption key in preparation for rotating production VSP
  keys and certificates

## [Release 069] - 2020-04-02

- Improve message shown when inconsistent payroll information is found
- Service operators can add a support ticket to claims
- Display the claim's decision within the heading on the task view page

## [Release 068] - 2020-03-31

- Service operators can add notes to claims
- Display "Removed" when personal data from the tasks view is removed
- Remove warning banners for matching claims and missing payroll gender
- Remove decision form from the full claim view
- Redirect user to the tasks view instead of full claim view when searching or
  amending a claim

## [Release 067] - 2020-03-30

- Exclude claims from previous academic years on matching claims screen
- Fix a bug with automated DQT checks where the report has multiple rows for the
  same claim
- Allow a claim's decision to be amended by a service operator
- Move claim amendments to a seperate tab
- Automated DQT checks verify that the surname in DQT matches the one in the
  claim

## [Release 066] - 2020-03-25

- Support searching for claims with more than just the reference
- Service operators can upload the report from DQT and perform automated
  qualification checks

## [Release 065] - 2020-03-24

- Show the academic year when viewing a claim
- Allow service operators to amend student loan amount

## [Release 064] - 2020-03-18

- Add "Back" link and page title to claim decision screen
- Link claim tasks view back to the list of claims
- Add a Missing Payroll Gender task to allow service operators to update a
  claim's Payroll Gender if it's not specified

## [Release 063] - 2020-03-16

- Add a task to check claims with matching attributes
- Add a claim checking task to verify identity of claimants who didn’t use
  GOV.UK Verify

## [Release 062] - 2020-03-12

- Add Yes/No option to claim checking tasks
- Update payment removal content

## [Release 061] - 2020-03-11

- Add a task for confirming the student loan amount on Student Loans claims
- Student Loans claims default to new task-based claim checking interface
- Claim checking tasks have unique headings
- Show NI number in the claim summary

## [Release 060] - 2020-03-10

- Fix question bug on school search results page
- Show a list of incomplete checks on the claim decision page
- Exclude claims for the other policy from claims with matching details

## [Release 059] - 2020-03-09

- Links that look like buttons now work if users have JS on the claim journey
- Links styled as buttons now work as expected for keyboard users
- Manage services page validates in html checker
- Improve guidance on admin file upload when no file is selected
- Add visually hidden text to manage services
- Screen reader improvements when viewing payrun
- Add visually hidden text to payroll history table
- Add visually hidden text to GIAS school link
- Allow service operators to navigate to decision page
- Financial year for student loans claims varies based on the current academic
  year

## [Release 058] - 2020-03-03

- Adjust content on the service closed page
- Security: Bump omniauth dependency to 1.9.1

## [Release 057] - 2020-03-03

- QTS question will vary based on the year the service is accepting claims for
- QTS answer will vary in admin based on the year the claim was made
- Claim decision page is shown at the end of the checks process
- A service operator can amend a claim
- Update static error pages (404, 422, 500) to make them policy-agnostic

## [Release 056] - 2020-02-25

- Allow service operators to mark a check as completed
- Update school eligibility to include City Technology Colleges
- Service operators are taken straight to the tasks list when checking a Maths
  and Physics claim
- Handle byte order mark when reading payment confirmation CSV

## [Release 055] - 2020-02-24

- Fix skipped heading level on manage services screen
- Add label to Payroll Cantium link
- Fix empty th on view claims screen
- Add page titles to admin area
- Run multiple worker instances so long-running queued jobs don't entirely block
  the queue
- Don't use "1" or "I" characters in claim references to avoid confusion
- Adjust option for not teaching eligible subjects for student loans

## [Release 054] - 2020-02-19

- The admin page for a claim no longer warns about a missing payroll gender once
  a decision has been made
- Iterate content on the Verify without Verify journey
- Service operators can change the academic year a policy is accepting claims
  for
- Service operators can view qualification and employment checks
- PII is automatically deleted from claims which are either rejected and have
  had no update in the last two months, or which have been paid more than two
  months ago
- Update "What information is sent" to include Cantium
- Swap Net/HTTP for HTTPClient when downloading the school data file to resolve
  a memory issue

## [Release 053] - 2020-02-12

- Don't share the last seen at session variables
- Fix bug causing school search button text to change when user clicks on it
- Add subheader to student loans questions
- Add a component saying why ask about student loans
- New copy when claim has been removed from payrun
- Claims now track the academic year they were made in

## [Release 052] - 2020-02-10

- Update admin menu with new layout
- Update "Some of this information is wrong" content on the verified page
- A Service Operator can remove problematic payments from a payroll run

## [Release 051] - 2020-02-03

- Allow claimants to search by school postcode
- Replace "passed SLA deadline" true/false with ok/warning/passed status in
  Geckoboard dataset
- Schools check email export no longer includes claims which have been checked
- Schools check email export now includes the claim school for claims made under
  the Student Loans policy

## [Release 050] - 2020-01-30

- Claim award amount is now sent to the Geckoboard dataset
- Identify claimants by teacher reference number instead of NI number
- Fix date sent to user in three week reminder email
- Better handling of issues related to browser caching and session expiration/
  timeouts

## [Release 049] - 2020-01-29

- Prevent service operator from approving a claim if we would not be able to pay
  it in the current payroll month because we are already paying the same
  claimant for another claim with different payment details
- Emails are sent for unchecked claims three weeks after they are submitted,
  advising users that their claim is still in progress
- Developers can export data needed for school check mail merge

## [Release 048] - 2020-01-28

- QLS questions now refer to academic year, instead of "1 September"
- Styling tweaks to make the service AAA accessible. Accessiblity updated to
  reflect AAA status
- Remove basic authentication on the Maths and Physics journey
- Update the "Claim submitted" page so all journeys link to the done page on
  GOV.UK
- Remove the temporary Maths and Physics start page and redirect to the one on
  GOV.UK
- New Maths and Physics feedback form link
- Put Maths and Physics into public beta

## [Release 047] - 2020-01-23

- Fix existing session page so if no option is selected a user doesn't continue
  their claim
- Update Geckoboard with how many claims are passed their check deadline
- Log entries are now tagged with their deployed environment
- Record the the time in days between submitting and approving a claim
- Add a Rake task to update a Geckoboard dataset when a new field has been added

## [Release 046] - 2020-01-21

- Feedback link tells users it will open in a new tab
- Changed existing session page to use radios and tidy up the iterruption card
- Semantic Logger has been added to make log entries more concise and useful
- Application logs can now be sent to Logstash for aggregation, analysis and
  monitoring
- Allow unverified addresses from GOV.UK Verify responses
- Unsubmitted claims are purged every 24 hours
- Batch Geckoboard data when submitting to the API

## [Release 045] - 2020-01-16

- Changed buttons on information-provided and eligibility confirmed pages to be
  actual buttons
- Check your answers page now has ARIA labels on the change buttons so screen
  readers will now tell users what they will change by visiting the link
- Removed unnecessary tags on main and footer elements that were causing
  warnings on validators
- A Payment date is set when a payroll run is ingested
- Backfill data about historic claims in Geckoboard

## [Release 044] - 2020-01-14

- Schools in the West Somerset opportunity area are now regarded as eligible
  again, after the West Somerset local authority district ceased to exist
- Service operators can approve claims that did not complete GOV.UK Verify
- Claims that have skipped GOV.UK Verify are identified in admin
- Bank account numbers must be exactly 8 digits long (6- and 7-digit numbers are
  no longer accepted)
- Multiple approved claims from the same person are grouped in to one payment
- Fix "Sorry, something went wrong" message displayed by GOV.UK Verify when
  claimant clicks "Continue" button on /verify/authentications/new page
- Include full name in claims report so it can be used to make TPS data requests

## [Release 043] - 2020-01-08

- Update to privacy policy to explain how data can be amended and add bullet
  point about collecting bank details
- Users can complete and submit a claim without completing GOV.UK Verify
- Update autocomplete attributes for the address capture page
- Application complete page and claim submitted email updated to include content
  for claimants that do not complete GOV.UK Verify
- Service operators can see who approved a claim
- Service operators can see who created a payroll run
- Fix a bug where users who spent more than 90 minutes in Verify would trigger a
  routing exception and not receive the session timeout message
- Service operators can see who downloaded a payroll run
- Show a warning message when a user tries to switch policies or start a new
  claim

## [Release 042] - 2019-12-19

- Import users from DfE Signin to the local database
- Bump Rack library dependency with security update

## [Release 041] - 2019-12-17

- Restore uptime alerting to alert when the App / VSP are down
- Don't match bank account sort code when identifying potentially similar claims
- Alternative provisions schools and special schools that teach students who are
  over 11 are eligible
- Update content for both maths and physics and student loans ineligible screens
- Update student loan question wording to make the intention clearer

## [Release 040] - 2019-12-09

- Load the admin IP whitelist from the Key vault

## [Release 039] - 2019-12-06

- Service operators can create and view a payroll run and provide a link to
  payroll operators (Cantium users) to download a file
- Payroll operators can download the payroll run file using a link
- Security: Bump puma from 4.3.0 to 4.3.1 to resolve Keepalive thread
  overload/DoS vulnerability

## [Release 038] - 2019-12-04

- Service operators can see Maths and Physics claim eligibility
- Fix a bug that would occasionally redirect users even after they'd continued
  their session
- Redirect requests to the root URL to a GOV.UK page about teacher payments

## [Release 037] - 2019-11-28

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
- "How we use the information you provided" content works for both policies

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
  location that the teacher _taught_ at, not where their employer is based
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
  that have been used in other claims. The other claims are listed and linked.

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
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-089...HEAD
[release 089]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-088...release-089
[release 088]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-087...release-088
[release 087]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-086...release-087
[release 086]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-085...release-086
[release 085]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-084...release-085
[release 084]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-083...release-084
[release 083]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-082...release-083
[release 082]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-081...release-082
[release 081]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-080...release-081
[release 080]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-079...release-080
[release 079]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-078...release-079
[release 078]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-077...release-078
[release 077]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-076...release-077
[release 076]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-075...release-076
[release 075]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-074...release-075
[release 074]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-073...release-074
[release 073]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-072...release-073
[release 072]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-071...release-072
[release 071]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-070...release-071
[release 070]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-069...release-070
[release 069]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-068...release-069
[release 068]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-067...release-068
[release 067]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-066...release-067
[release 066]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-065...release-066
[release 065]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-064...release-065
[release 064]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-063...release-064
[release 063]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-062...release-063
[release 062]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-061...release-062
[release 061]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-060...release-061
[release 060]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-059...release-060
[release 059]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-058...release-059
[release 058]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-057...release-058
[release 057]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-056...release-057
[release 056]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-055...release-056
[release 055]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-054...release-055
[release 054]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-053...release-054
[release 053]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-052...release-053
[release 052]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-051...release-052
[release 051]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-050...release-051
[release 050]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-049...release-050
[release 049]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-048...release-049
[release 048]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-047...release-048
[release 047]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-046...release-047
[release 046]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-045...release-046
[release 045]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-044...release-045
[release 044]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-043...release-044
[release 043]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-042...release-043
[release 042]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-041...release-042
[release 041]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-040...release-041
[release 040]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-039...release-040
[release 039]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-038...release-039
[release 038]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-037...release-038
[release 037]:
  https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/release-036...release-037
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
