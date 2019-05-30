# Teacher’s Payment Service

## Documentation

Documentation can be found in the [docs](docs) directory.

### ADRs

Architecture decision records can be found in the
[architecture-decisions](docs/architecture-decisions) directory.

## Prerequisites

- Ruby 2.6.2
- PostgreSQL

## Setting up the app in development

1. In order to integrate with DfE Sign-in's Open ID Connect service we are
   required to communicate over https in development. Create a self-signed
   development certificate.
   - Run `openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout localhost.key -out localhost.crt`
   - Open Keychain Access on your Mac and go to the Certificates category in
     your System keychain. Once there, import the `localhost.crt`
     `File > Import Items`. Double click the imported certificate and change the
     “When using this certificate:” dropdown to `Always Trust` in the Trust
     section.
2. Run `bundle install` to install the gem dependencies
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
DFE_SIGN_IN_REDIRECT_URL=https://localhost:3000/admin/auth/callback
DFE_SIGN_IN_IDENTIFIER=<paste identifier>
DFE_SIGN_IN_SECRET=<paste secret>
```

The identifier and secret are stored in Heroku.

## Running specs, brakeman, and code linting

```bundle exec rake```

### Code linting rules

Using the standardrb gem:

https://github.com/testdouble/standard

### N+1 query detection

[Bullet](https://github.com/flyerhzm/bullet) runs around each spec. If it detects an N+1 query it will raise an
exception and the tests will fail.

## Service architecture

The service architecture is currently defined and maintained here:

  https://miro.com/app/board/o9J_kxw-xdU=/

## Access

Both staging and production are protected by HTTP Basic Authentication, these
details are pinned in the *dfe-teacher-payments* slack channel or can be found
in the *Config Vars* in Heroku.

### Staging

https://dfe-teachers-payment-staging.herokuapp.com/

### Production

https://dfe-teachers-payment-prod.herokuapp.com/
