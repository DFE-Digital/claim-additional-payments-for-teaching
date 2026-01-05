# First-line support developer runbook

The audience for this document is a developer working on first-line support, who
may not have worked on this service before. It explains how to perform some
tasks that you might get asked to do.

## Support tasks

If you want to do one of these tasks and you don’t have what you need, see the
[first-line support onboarding list](developer-onboarding.md#first-line-support-onboarding).

### I want to make a bug fix and deploy it

#### You will need

- permissions to open a pull request in the repository
- credentials for DfE’s Cloud Infrastructure platform and membership of an
  Active Directory group that allows you to perform a release — here’s how to
  check:

  1. Log in to https://portal.azure.com with your `@digital.education.gov.uk`
     email address.
  2. Search for `s189-teacher-services-cloud-production`.
  3. Click “My permissions”.
  4. If you see something like

     > You are a member of the group 's189 SRTL delivery team ()' which has been
     > assigned the role 'Reader' (type BuiltInRole) and has access to
     > s189-teacher-services-cloud-production

     then you have what you need.

#### You may need

- credentials for DfE Sign-in pre-production, if you’re investigating a bug in
  the `/admin` site — see [`dfe-sign-in.md`](dfe-sign-in.md)

#### Steps

1. Set up the app locally. See
   [`README.md#setting-up-the-app-locally`](../README.md#setting-up-the-app-locally).

   If you need to try out something in the `/admin` site locally, see
   [how to set up DfE Sign-in locally](../README.md#how-to-set-up-dfe-sign-in-locally).

2. Fix the bug.
3. Describe the fix in [`CHANGELOG.md`](../CHANGELOG.md).
4. Open a pull request into `master`.
5. Deploy a review app by adding the 'Deploy' tag to your PR and get it
   reviewed.
6. Merge the pull request.

### I want to pull some data from the production database

#### You will need

- credentials for the project’s Azure infrastructure

#### Steps

1. Make a Privileged Identity Management (PIM) request, to gain the elevated
   permissions required to access production resources. See
   [`privileged-identity-management-requests.md`](privileged-identity-management-requests.md).
2. Ask another developer to approve the PIM request.
3. Start a Rails console. See
   [`README.md#accessing-production-data-with-a-live-rails-console`](../README.md#accessing-production-data-with-a-live-rails-console).

### I want to investigate an error

#### You may need

- access to the production Logit.io stack for the service, to view the web and
  worker logs
- access [Sentry](https://dfe-teacher-services.sentry.io/issues), to view details of exceptions

#### How to do it

- To view logs (web, worker, container), see [`logging.md`](logging.md).
- To view details of exceptions, see the [Sentry](https://dfe-teacher-services.sentry.io/issues)

### I want to export data for the “school check email”

Someone from DfE will probably ask us to do this at least once a month whilst
there is a claim window open, which is around September – March.

#### You will need

- credentials for DfE’s G Suite - i.e. an `@digital.education.gov.uk` email
  address
- credentials for DfE’s Cloud Infrastructure platform and membership of an
  Active Directory group that allows you to connect to a production container —
  here’s how to check:

  1. Log in to https://portal.azure.com with your `@digital.education.gov.uk`
     email address.
  2. Search for `s189-teacher-services-cloud-production`.
  3. Click “My permissions”.
  4. If you see something like

     > You are a member of the group 's189 SRTL delivery team ()' which has been
     > assigned the role 'Reader' (type BuiltInRole) and has access to
     > s189-teacher-services-cloud-production

     then you have what you need.

#### How to do it

Follow the steps in [`school-check-data.md`](school-check-data.md). The
“relevant service operator” which that document refers to is probably the person
who raised the support ticket.

### I want to remove the 'downloaded' state from a payroll run so it can be downloaded again

#### You will need

- credentials for the project’s Azure infrastructure

#### Steps

1. Make a Privileged Identity Management (PIM) request, to gain the elevated
   permissions required to access production resources. See
   [`privileged-identity-management-requests.md`](privileged-identity-management-requests.md).
2. Ask another developer to approve the PIM request.
3. Start a Rails console. See
   [`README.md#accessing-production-data-with-a-live-rails-console`](../README.md#accessing-production-data-with-a-live-rails-console).
4. Identify the latest `PayrollRun` object (double check that the dates are as
   expected), set `downloaded_at` and `downloaded_by_id` to `nil` and save the
   object:

   ```ruby
   payroll = PayrollRun.last
   payroll.downloaded_at = nil
   payroll.downloaded_by_id = nil
   payroll.save
   ```

### I want to restart the worker container instance

#### You will need

- credentials for the project’s Azure infrastructure

#### Steps

1. Make a Privileged Identity Management (PIM) request, to gain the elevated
   permissions required to access production resources. See
   [`privileged-identity-management-requests.md`](privileged-identity-management-requests.md).
2. Ask another developer to approve the PIM request.

Then run:

```bash
kubectl -n srtl-production rollout restart deployment claim-additional-payments-for-teaching-production-worker
```

If you need more detailed information about the rollout status, you can describe
the deployment:

```bash
kubectl -n srtl-test describe deployment
claim-additional-payments-for-teaching-production-worker
```
