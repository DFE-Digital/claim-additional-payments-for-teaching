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

- Ruby 2.6.2
- PostgreSQL
- [Yarn](https://yarnpkg.com/en/docs/install)

You will also need Java 11 or a long term supported version of Java 8 installed
for the Verify Service Provider to run. We recommend [OpenJDK][openjdk].

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
4. Run `bundle exec foreman start` to launch the app on https://localhost:3000

### DfE Sign In credentials

By default in development OmniAuth will run in test mode. This means that you
don't need to authenticate with DfE Sign In. If you need to run development with
integration with DfE Sign In, you need to provide the relevant environment
variables.

Create a `.env` file with the following variables:

```
DFE_SIGN_IN_ISSUER=https://pp-oidc.signin.education.gov.uk:443
DFE_SIGN_IN_REDIRECT_BASE_URL=https://localhost:3000
DFE_SIGN_IN_IDENTIFIER=<paste identifier>
DFE_SIGN_IN_SECRET=<paste secret>
DFE_SIGN_IN_API_CLIENT_ID=teacherpayments
DFE_SIGN_IN_API_SECRET=<paste secret>
DFE_SIGN_IN_API_ENDPOINT=https://pp-api.signin.education.gov.uk
```

The identifier and secret are stored in Heroku.

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

### Running `CronJob`s

To schedule recurring jobs, run the following:

```
rake jobs:schedule
```

## Running specs, brakeman, and code linting

```
bundle exec rake
```

To run the feature specs you will need Chrome installed.

### Code linting rules

Code linting is performed using:

- [Standard](https://github.com/testdouble/standard) for Ruby
- [Prettier](https://prettier.io/) for everything else

### N+1 query detection

[Bullet](https://github.com/flyerhzm/bullet) runs around each spec. If it
detects an N+1 query it will raise an exception and the tests will fail.

## Deployment

### Development

Development is automatically built and deployed when commits are pushed to
`master`.

### Production

To do a production release:

1. Log in to this project on [Azure DevOps](azure-devops).
2. Navigate to _Pipelines_ > _Builds_.
3. Find the build you want to release and note its _Build #_ (e.g.
   `20190717.2`). You can filter by branch using the filter / funnel icon in the
   top right.
4. Navigate to _Pipelines_ > _Releases_.
5. Click on the _Deploy_ release pipeline.
6. Click on the release matching the _Build #_ of the build you want to release.
7. Click on _Deploy Production_ and manually trigger the deployment.

This will release to production using the same configuration as the matching
development release. If that configuration is no longer valid, you could create
a new release using the most up to date configuration, or you could modify the
configuration of the matching release found in step 6, depending on needs.
Further related steps are left as an exercise for the reader.

## Service architecture

The service architecture is currently defined and
[on confluence](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1049559041/Service+Architecture).

## Access

Staging is protected by HTTP Basic Authentication. The username and password are
pinned in the _dfe-teacher-payments_ slack channel or can be found in the
_Config Vars_ in Heroku.

### Staging

https://dfe-teachers-payment-staging.herokuapp.com/

[azure-devops]: https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service
[openjdk]: https://adoptopenjdk.net/
