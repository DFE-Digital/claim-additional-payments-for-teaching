[![Build Status](https://dfe-ssp.visualstudio.com/S118-Teacher-Payments-Service/_apis/build/status/DFE-Digital.dfe-teachers-payment-service?branchName=master)](https://dfe-ssp.visualstudio.com/S118-Teacher-Payments-Service/_build/latest?definitionId=197&branchName=master)

# Claim Additional Payments for Teaching

## Documentation

Most documentation for the service can be found on the
[project's Confluence wiki](https://dfedigital.atlassian.net/wiki/spaces/TP).
Some app-specific technical documentation can be found in the [docs](docs)
directory.

### First-line support developers

If you’re a developer on first-line support who is new to this project, see the
[support runbook (`docs/first-line-support-developer-runbook.md`)](docs/first-line-support-developer-runbook.md)
for help with common support tasks.

### Service architecture

The service architecture is currently defined
[on Confluence](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1049559041/Service+Architecture).

### ADRs

Architecture decision records can be found in the
[architecture-decisions](docs/architecture-decisions) directory.

### Documentation for common developer tasks

- Release process for production:
  [`docs/release-process.md`](docs/release-process.md)
- Generating school check data:
  [`docs/school-check-data.md`](docs/school-check-data.md)

## Prerequisites

- Java 11 or 8 (LTS) - we recommend [OpenJDK](https://adoptopenjdk.net/)
- Ruby 2.6.2
- PostgreSQL
- [ShellCheck](https://www.shellcheck.net/)
- [Yarn](https://yarnpkg.com/en/docs/install)

## Setting up the app locally

1. In order to integrate with DfE Sign-in's Open ID Connect service we are
   required to communicate over https in development. Create a self-signed
   development certificate.
   - Run
     `openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout localhost.key -out localhost.crt`
   - Open Keychain Access on your Mac and go to the Certificates category in
     your System keychain. Once there, import the `localhost.crt`
     `File > Import Items`. Double click the imported certificate and change the
     “When using this certificate:” dropdown to `Always Trust` in the Trust
     section.
2. Run `bundle install` and `yarn install` to install the dependencies
3. Fetch the `DFE_SIGN_IN_API_SECRET` development secret from the
   [Azure key vault](docs/secrets.md) and store it in `.env` at the root of the
   repository.
4. Run `bundle exec rails db:setup` to set up the database development
5. Run `bundle exec foreman start` to launch the app on https://localhost:3000/
6. Visit one of the following urls in your browser to access the relevant
   policy:

- **Student Loans:** https://localhost:3000/student-loans/claim
- **Maths and Physics:** https://localhost:3000/maths-and-physics/claim

### How to set up DfE Sign-In locally

The service uses DfE Sign In to handle admin users.

To use the `/admin` site locally, you need the secret configuration variables
for DfE Sign In's pre-production environment. You can find these in the
development key vault on Azure.

Create a `.env` file at the root of the repository, with the following
variables:

```
DFE_SIGN_IN_SECRET=<paste secret>
DFE_SIGN_IN_API_SECRET=<paste secret>
```

To access the admin routes, you will also need to
[request an account on DfE Sign In's pre-production environment](docs/dfe-sign-in.md#adding-a-new-user-to-the-pre-production-environment).

### GOV.UK Notify

We use Notify to send emails however it is turned off by default in development.
If you want to test Notify in development you will need an API key and add it to
your `.env` file. Make sure you use a 'test' or 'team' API key only.

```
NOTIFY_API_KEY=<paste api key>
```

### Google Analytics

To enable Google Analytics set the following environment variable:

```
GOOGLE_ANALYTICS_ID=<UA PROPERTY>
```

### Running `CronJob`s

To schedule recurring jobs, run the following:

```
rake jobs:schedule
```

Look for jobs that inherit from `CronJob` for a complete list of scheduled jobs.

## Storing non-essential cookies

Non-essential cookies should not be stored without the user's consent. If the
user has given consent, we record it in a cookie called `accept_cookies`.

In JavaScript before setting a cookie, you can check the user's consent by using
the function: `TeacherPayments.cookies.checkNonEssentialCookiesAccepted()`

## Geckoboard

The application has a Geckoboard dashboard that is updated every time a Claim is
submitted or approved, or a payment is recorded. The class that does most of the
work can be found in app/models/claim/geckoboard_dataset.rb.

If any changes are made to the `DATASET_FIELDS` constant, then it's important
that the underlying Geckoboard dataset is reset, as the Geckoboard API doesn't
support adding new fields to an already existing dataset. The easiest way to do
this is to run the following Rake command:

```bash
bundle exec rake geckoboard:reset
```

This deletes the existing dataset, and then recreates the dataset with the
exisiting claim data.

## Running specs, brakeman, and code linting

```
bundle exec rake
```

To run the feature specs you will need Chrome installed.

### Code linting rules

Code linting is performed using:

- [Standard](https://github.com/testdouble/standard) for Ruby
- [ShellCheck](https://www.shellcheck.net/) for shell scripts
- [Prettier](https://prettier.io/) for everything else

### N+1 query detection

[Bullet](https://github.com/flyerhzm/bullet) runs around each spec. If it
detects an N+1 query it will raise an exception and the tests will fail.

### The use of Rails fixtures in the test suite

The application test suite makes use of a small number of
[Rails fixtures](https://api.rubyonrails.org/v5.2.1/classes/ActiveRecord/FixtureSet.html)
for some key models: School, LocalAuthority, and LocalAuthorityDistrict. This is
because these models map to real-world entities with unique identifiers, and
these identifiers are used as constants in the eligibility code. For example,
the local authority of Barnsley is eligible for student loans as it's local
authority code is listed in
`StudentLoans::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_CODES`. By using
fixtures for a small number of these real-world entities we avoid potentially
flaky fixtures for things like eligible schools or districts where these unique
identifiers may clash. See the School factory for how the eligible school traits
make use of the local authority and district fixtures to create eligible
schools.

## Loading the full schools list in development

In development we do not automatically seed the database with the full list of
schools (as supplied by the Get Information About Schools service). To import
the full data set for schools run `rails schools_data:import`. This can take a
few minutes to complete.

## Creating data migrations

When running a live service sometimes you're required to change existing data in
some way. We do this in a similar way to database migrations, using Data
Migrations

The migrations are stored in the `db/data` folder.

- To generate a migration: `rails g data_migration add_this_to_that`
- To run the data migration:
  `rails runner db/data/$FILENAME_OF_THE_GENERATED_MIGRATION`

When the new code deploys, you'll need to run your migration on the live service
by [running a live console](#running-a-live-console).

## Generating Code Coverage report

Simplecov gem has been installed and the report is generated from a successful
run by running the following command `bundle exec rspec`. For a more detailed
report click on the generated link

## Deployment

### Development

Development is automatically built and deployed when commits are pushed to
`master`.

You can check the progress of the build and release in
[Azure DevOps](https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service).

The development website is at
https://development.additional-teaching-payment.education.gov.uk.

### Production

The release process for Production is documented in
[`docs/release-process.md`](docs/release-process.md)

### Heroku Review Apps

Pull requests in the
[GitHub Repository](https://github.com/DFE-Digital/dfe-teachers-payment-service)
will automatically have a
[review app](https://devcenter.heroku.com/articles/github-integration-review-apps)
created in Heroku once CI has passed.

For more information, see the [app's Heroku docs](docs/heroku.md)

## Accessing production data with a live Rails console

**Accessing a live console is very risky and should only be done as a last
resort. This should only be done in pairs, and mutating any live data is
STRONGLY discouraged.**

The console will be ran inside a container instance and won't be on one of the
web servers, however it will have access to the database.

### Through the Azure UI

- Navigate to the
  [container instance](https://portal.azure.com/#blade/HubsExtension/BrowseResourceBlade/resourceType/Microsoft.ContainerInstance%2FcontainerGroups)
  resource (eg. `s118d01-app-worker-aci`)
- Then go to 'Containers' under 'Settings'
- With the container selected go to the 'Connect' tab
- Choose the start up command (`/bin/bash` is recommended) and connect
- From there, you can run a Rails console with `bin/rails console`. Pass the
  `--sandbox` flag if you don’t need to modify data.

### Through the Azure CLI

We have a helpful script you can run that will connect you to the right resource
(you will need the [Azure CLI](https://docs.microsoft.com/en-gb/cli) installed
first):

```bash
bin/azure-console $ENVIRONMENT # (development/production)
```

From there, you can run a Rails console with `bin/rails console`. Pass the
`--sandbox` flag if you don’t need to modify data.

Accessing a live console on production requires a
[PIM (Privileged Identity Management) request](docs/privileged-identity-management-requests.md)

### Usage

When accessing the Rails console on a live system, do so in sandbox mode to
avoid making unintented changes to the database state:

`bin/rails console --sandbox`.

In exceptional circumstances you may want to modify the data. If this is the
case, you should probably write a [data migration](#creating-data-migrations) so
that the code to do it can be reviewed and put into source control. If there is
a need to make an immediate change live using the console, make sure it is done
with approval from the Service Owner and is to done as a pair.

## Opening/closing services for applications

It is possible to close each service for applications in the admin interface
under "Manage services" by changing the service status from "Open" to "Closed".
When closed, the public-facing interface for making claims is disabled and a
message explaining that the service is down is displayed. The admin interface
remains open.

There are a few reasons each service might need to be closed:

- At the end of the April when the service closes for applications until the
  next academic year
- When there is release planned that requires the site be temporarily be
  disabled because of the changes being made
- When there is unplanned maintenance because of an issue or incident.

## Reusable components

A number of classes and components within this application have been written
such that they are decoupled from the specifics of this service and could easily
be reused in other projects.

### DfE Sign-in

There are a couple of utility classes in the [`lib`](lib) folder under the
`DfeSignIn` namespace for interacting with DfE Sign-in single sign-on and the
DfE Sign-in API.

### Application Insights

There is reusable code that enhances the `application_insights` gem to include
the user IP address as part of the payload data sent to Application Insights in
[`lib/application_insights`](lib/application_insights). See
[`config/initializers/application_insights.rb`](config/initializers/application_insights.rb)
for how to mixin this code to your Rails application.

### Azure ARM templates

There are some templates that we've abstracted out of our resource group
templates, which are likely useful for other projects. Find them in
[`azure/templates`](azure/templates). You can copy them, or include them in your
template directly using a `Microsoft.Resources/deployments` resource. For
example:

```json
{
  "type": "Microsoft.Resources/deployments",
  "apiVersion": "2017-05-10",
  "name": "DEPLOYMENT_NAME",
  "properties": {
    "mode": "Incremental",
    "templateLink": {
      "uri": "https://raw.githubusercontent.com/DFE-Digital/dfe-teachers-payment-service/COMMIT_SHA_OR_BRANCH_NAME/azure/templates/NAME.json",
      "contentVersion": "1.0.0.0"
    },
    "parameters": {}
  }
}
```
