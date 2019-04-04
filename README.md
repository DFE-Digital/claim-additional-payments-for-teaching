# Teacher’s Payment Service

## Documentation
Documentation can be found in the [docs](docs) directory.

### ADRs
Architecture decision records can be found in the [architecture-decisions](docs/architecture-decisions) directory.



## Prerequisites
- Ruby 2.6.2
- PostgreSQL

## Setting up the app in development

1. Run `bundle install` to install the gem dependencies
2. Run `bundle exec rails db:setup` to set up the database development
3. Run `bundle exec rails server` to launch the app on http://localhost:3000

## Running specs and Rubocop

```bundle exec rake```

### Rubocop rules
From the dxw utils project:

https://github.com/dxw/dxw-utils

## Access
Both staging and production are protected by HTTP Basic Authentication, these details are pinned in the *dfe-teacher-payments* slack channel or can be found in the *Config Vars* in Heroku.

### Staging

https://dfe-teachers-payment-staging.herokuapp.com/

### Production

https://dfe-teachers-payment-prod.herokuapp.com/
