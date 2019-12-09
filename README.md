[![Build Status](https://dfe-ssp.visualstudio.com/S118-Teacher-Payments-Service/_apis/build/status/DFE-Digital.dfe-teachers-payment-service?branchName=master)](https://dfe-ssp.visualstudio.com/S118-Teacher-Payments-Service/_build/latest?definitionId=197&branchName=master)

# Claim Additional Payments for Teaching

## Documentation

Most documentation for the service can be found on the
[project's confluence wiki](https://dfedigital.atlassian.net/wiki/spaces/TP).
Some app-specific technical documentation can be found in the [docs](docs)
directory.

### ADRs

Architecture decision records can be found in the
[architecture-decisions](docs/architecture-decisions) directory.

## Prerequisites

- Java 11 or 8 (LTS) - we recommend [OpenJDK][openjdk]
- Ruby 2.6.2
- PostgreSQL
- [ShellCheck](https://www.shellcheck.net/)
- [Yarn](https://yarnpkg.com/en/docs/install)

## Setting up the app in development

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
3. Run `bundle exec rails db:setup` to set up the database development
4. Run `bundle exec rails data:schema:load` to seed the data migrations
   information
5. Run `bundle exec foreman start` to launch the app on https://localhost:3000/
6. Visit one of the following urls in your browser to access the relevant
   policy:

- **Student Loans:** https://localhost:3000/student-loans/claim
- **Maths and Physics:** https://localhost:3000/maths-and-physics/claim

### DfE Sign In credentials

The service uses DfE Sign In to handle admin users. To run in development, you
need the credentials for DfE Sign In's pre-production environment.

Create a `.env` file with the following variables:

```
DFE_SIGN_IN_SECRET=<paste secret>
DFE_SIGN_IN_API_SECRET=<paste secret>
```

The secrets are stored in the development Key Vault on Azure.

To access the admin routes, you will also need to request an account on DfE Sign
In's pre-production environment.

### GOV.UK Notify

We use Notify to send emails however it is turned off by default in development.
If you want to test Notify in development you will need an API key and template
ID and add them to your `.env` file. Make sure you use a 'test' or 'team' API
key only.

```
NOTIFY_API_KEY=<paste api key>
NOTIFY_TEMPLATE_ID=d72e2ff9-b228-4f16-9099-fd9d411c0334
```

### GOV.UK Verify

The service uses GOV.UK Verify to verify the identity of teachers that are
claiming.

See [docs/govuk-verify](/docs/govuk-verify.md) for more details on this.

### Google Analytics

To enable Google Analytics set the following environment variable:

```
GOOGLE_ANALYTICS_ID=<UA PROPERTY>
```

### Storing non-essential cookies

Non-essential cookies should not be stored without the user's consent. If the
user has given consent, we record it in a cookie called `accept_cookies`.

In JavaScript before setting a cookie, you can check the user's consent by using
the function: `TeacherPayments.cookies.checkNonEssentialCookiesAccepted()`

### Running `CronJob`s

To schedule recurring jobs, run the following:

```
rake jobs:schedule
```

Look for jobs that inherit from `CronJob` for a complete list of scheduled jobs.
Currently there is a single scheduled job for importing the schools data once a
day at 4am: `SchoolDataImporterJob`.

## Running specs, brakeman, and code linting

```
bundle exec rake
```

To run the feature specs you will need Chrome installed.

### Running a live console

**Accessing a live console is very risky and should only be done as a last
resort. This should only be done in pairs, and mutating any live data is
STRONGLY discouraged.**

The console will be ran inside a container instance and won't be on one of the
web servers, however it will have access to the database.

#### Through the Azure UI

- Navigate to the
  [container instance](https://portal.azure.com/#blade/HubsExtension/BrowseResourceBlade/resourceType/Microsoft.ContainerInstance%2FcontainerGroups)
  resource (eg. `s118d01-app-worker-aci`)
- Then go to 'Containers' under 'Settings'
- With the container selected go to the 'Connect' tab
- Choose the start up command (`/bin/bash` is recommended) and connect

#### Through the Azure CLI

We have a helpful script you can run that will connect you to the right resource
(you will need the [Azure CLI](https://docs.microsoft.com/en-gb/cli) installed
first):

```bash
bin/azure-console $ENVIRONMENT # (development/production)
```

#### Usage

If you don't need to modify the data and only need to do queries it is
recommended that you run rails console in sandbox mode
`rails console --sandbox`.

In exceptional circumstances you may want to modify the data, this should only
be done with approval from the Service Owner and is to be carried out in pairs.

Accessing a live console on production requires a
[PIM (Privileged Identity Management) request](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1192624202/Privileged+Identity+Management+requests).

### Code linting rules

Code linting is performed using:

- [Standard](https://github.com/testdouble/standard) for Ruby
- [ShellCheck](https://www.shellcheck.net/) for shell scripts
- [Prettier](https://prettier.io/) for everything else

### N+1 query detection

[Bullet](https://github.com/flyerhzm/bullet) runs around each spec. If it
detects an N+1 query it will raise an exception and the tests will fail.

## The use of Rails fixtures in the test suite

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
some way. Using the gem [data_migrate](https://github.com/ilyakatz/data-migrate)
we can write data migrations in a similar way we do with schema migrations.

The migrations are stored in the `db/data` folder.

- To generate a migration: `rails g data_migration add_this_to_that`
- To run the data migration: `rails data:migrate` run this separately from the
  schema migration

When the service deploys it will run these data migrations after the schema
ones. Any schema clean-up as a result of the data migration will need to be done
as a separate change.

## Deployment

### Development

Development is automatically built and deployed when commits are pushed to
`master`.

### Production

The release process for Production is documented in
[`docs/release-process.md`](docs/release-process.md)

## Service architecture

The service architecture is currently defined [on confluence].

[on confluence]:
  https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1049559041/Service+Architecture
[openjdk]: https://adoptopenjdk.net/

## Putting the application into maintenance mode

There are two potential reasons why we might want to turn maintenance mode on.
Either prior to a deploy of a journey breaking change, or until further notice
(the service is closed for some reason).

Maintenance mode is enabled on a per-policy basis via "Open or close a service"
in the admin web interface.

## Reusable components

A number of classes and components within this application have been written
such that they are decoupled from the specifics of this service and could easily
be reused in other projects.

### GOV.UK Verify

There are a number of documented classes in the [`lib`](lib) folder under the
`Verify` namespace that relate to integrating with GOV.UK Verify. You may find
these classes useful if your Rails-based service needs to integrate with GOV.UK
Verify.

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
