# Heroku

Pull requests in the
[GitHub Repository](https://github.com/DFE-Digital/dfe-teachers-payment-service)
will automatically have a
[review app](https://devcenter.heroku.com/articles/github-integration-review-apps)
created in Heroku once CI has passed. This app can be used to test and share the
behaviour of the pull request, and is particularly useful for acceptance of a
new feature or change.

## Configuration

### Deploying review apps for the first time

The review apps are configured in `app.json`, except for secret environment
variables which are configured in the Heroku admin interface. Broadly, they are
configured as follows:

- In-dyno Postgres databases are used to overcome permissions errors when
  loading fixtures.
- The `nodejs` buildpack is explicitly run first so dependencies for the asset
  pipeline are ready.
- The first time a review app is deployed it will have the database initialised
  and the test fixtures loaded to give example data.

The `test` configuration is not currently used in Heroku.

### Subsequent deploys to the same review app

As part of each app's
[release phase](https://devcenter.heroku.com/articles/release-phase) database
migrations are run as defined in the `postdeploy` option in the `Procfile`.
