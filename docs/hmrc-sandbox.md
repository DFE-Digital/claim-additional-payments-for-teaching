# HMRC sandbox employment data

These tasks use the Create Test User and Integration Framework Test Support APIs
documented in `hmrc-api-docs`. They create National Insurance individuals and DFE
employment responses; no Self Assessment enrolment or data is created.

## Configuration

Set the existing employment client variables in your local environment:

```sh
HMRC_EMPLOYMENTS_BASE_URL=https://test-api.service.hmrc.gov.uk
HMRC_EMPLOYMENTS_CLIENT_ID=...
HMRC_EMPLOYMENTS_CLIENT_SECRET=...
# HMRC_EMPLOYMENTS_TOTP_SECRET=... # if required by your application
```

Your sandbox application needs access to Create Test User, Integration Framework
Test Support, Individuals Matching and Individuals Employments (v2). The tasks
reuse the employment client's authentication, including optional TOTP. They
reject other base URLs. `HMRC_EMPLOYMENTS_ENABLED` does not gate these explicit
tasks; enable it separately when testing the wizard.

The token request uses `scope=assigned`. When the OAuth bypass secret is set,
the client prefixes the client secret with an eight-digit SHA512 TOTP (30-second
interval), matching the employment API's authentication flow. The variable is
`HMRC_EMPLOYMENTS_TOTP_SECRET` (TOTP, not TOPT). A misspelling leaves the OTP
disabled and can cause `invalid_client`. After changing `.env`, reload it; for
shell variables to reach subprocesses, use `set -a; source .env; set +a`.

## Create a teacher and one employment

To first diagnose access to the Create Test User API without creating a user:

```sh
bin/rails hmrc:sandbox:services
```

This calls `GET /create-test-user/services` with the same authentication and v1
Accept header as user creation, logs the endpoint/status and prints the returned
services as JSON. A failure exits with the HMRC error as usual.

```sh
bin/rails hmrc:sandbox:create_user \
  EMPLOYER_NAME='Example Nursery' PAYE_REFERENCE=123/AB456 \
  START_DATE=2025-09-01
```

Use the nursery's exact name: the current EYTFI employment check compares employer
names. `END_DATE=YYYY-MM-DD` is optional; omit it for an ongoing employment.
The generated name, date of birth, NINO and sign-in details are printed and saved
in `tmp/hmrc-sandbox/<NINO>.json`. The user is saved before employment is posted,
so a failed seed does not lose the identity. Files contain sandbox credentials
and are created with permissions `0600`; the directory is ignored by Git.

To create only the individual, omit the employment parameters:

```sh
bin/rails hmrc:sandbox:create_user
```

HMRC generates identity details. Optionally supply `NINO=AA123456A` to request a
particular test NINO (for example to align with another test system). Use the
returned identity when calling Individuals Matching.

## Seed an existing user's employments

```sh
bin/rails hmrc:sandbox:create_employments NINO=AA123456A \
  EMPLOYER_NAME='Example Nursery' PAYE_REFERENCE=123/AB456 \
  START_DATE=2025-09-01
```

For multiple employments, pass `EMPLOYMENTS_FILE=/path/to/employments.json` to
either `create_user` or `create_employments`. This replaces the single-employment
parameters and sends the supplied IF payload. For example:

```json
{
  "employments": [
    {
      "employerRef": "123/OLD",
      "employer": {"name": "Previous Nursery", "districtNumber": "123", "schemeRef": "OLD"},
      "employment": {"startDate": "2024-09-01", "endDate": "2025-08-31"}
    },
    {
      "employerRef": "123/NEW",
      "employer": {"name": "Example Nursery", "districtNumber": "123", "schemeRef": "NEW"},
      "employment": {"startDate": "2025-09-01"}
    }
  ]
}
```

Use `{"employments": []}` for an empty history. JSON mode checks the top-level
shape; HMRC validates the IF fields. No payment or Self Assessment data is needed.
All employment seeds use `useCase=DFE`. Optional `FROM_DATE` and `TO_DATE` set the
stub's `startDate` and `endDate` query parameters. These describe the requested
history window, independently of each employment's start/end dates. When setting
a window, use the same dates when fetching the history.

## Fetch employment history

To check whether supplied identity details match an individual in HMRC's sandbox:

```sh
bin/rails hmrc:sandbox:match_user FIRST_NAME=Seymour LAST_NAME=Skinner \
  NINO=AB123456C DATE_OF_BIRTH=1970-01-01
```

All four arguments are required. Quote names containing spaces. This uses
`POST /individuals/matching/` with the v2 Accept header, without needing a saved
identity or fetching employment data. Output contains `matched: true` and HMRC's
response (including the match link), or `matched: false` for `404 MATCHING_FAILED`.
A non-match means the supplied details did not match; it does not prove the NINO
does not exist. Other API errors fail the task as usual.

```sh
bin/rails hmrc:sandbox:fetch_employments NINO=AA123456A FROM_DATE=2025-09-01
# Optionally add TO_DATE=2026-09-30 and/or PAYE_REFERENCE=123/AB456
```

`fetch_employments` calls the real matching and employment endpoints through
`Hmrc::Employments::Client`, using the locally saved identity.

## API limitations

Sandbox requests log their HTTP method, full URL (including query parameters),
and response status to stderr. This includes OAuth, matching and employment
requests, so a `FORBIDDEN` response can be traced to its endpoint. Headers and
request/response bodies are not logged by the client. URLs can contain sandbox
NINOs and match IDs.

If both user creation and the services diagnostic return `403 FORBIDDEN` with
`This endpoint is not available`, check the application's IP allow list: a
changed public IP caused this response even though OAuth token issuance succeeded.

The supplied APIs have no endpoints for listing, retrieving, updating or deleting
test users, nor for updating or deleting seeded employment data. The IF docs say
each endpoint can be populated only once per user. Supply all employments in one
request. To change a scenario, create a new user and seed the revised history.
After an ambiguous network failure, try fetching the history before retrying a
seed: the first request may have succeeded.

Saved identity files allow `fetch_employments` to match users created by these
tasks. Removing a local file does not delete the HMRC user. HMRC says users unused
for 90 days are deleted; local files can outlive them. Preserve the files if you
want to fetch their employment history after clearing `tmp`.
