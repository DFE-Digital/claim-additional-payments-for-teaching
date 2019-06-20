# GOV.UK Verify Integration

A good place to start is to read the [GOV.UK Verify technical documentation](https://www.docs.verify.service.gov.uk/#gov-uk-verify-technical-documentation).

## Getting support

The email address for Verify support is idasupport@digital.cabinet-office.gov.uk
(which goes through to Zendesk). There is also a #govuk-verify slack channel
on the ukgovernmentdigital.slack.com slack workspace.

## Running locally in development

Currently GOV.UK Verify integration is under active development and can be
enabled by setting an environment variable in your `.env` file:

```bash
  GOVUK_VERIFY_ENABLED=1
```

GOV.UK Verify integration requires using a Verify Service Providor (VSP)
to handle SAML secure messaging. To run a VSP in development, you will
need to download the latest release ZIP from the [project on Gitub](https://github.com/alphagov/verify-service-provider/releases).
Note: only work with the pre-compiled releases and don't try and build from
source. The VSP can be started in development mode with:

```bash
  $ ./bin/verify-service-provider development -u https://localhost:3000/verify/response
```

This will start the VSP on port 50300. You can check that it is running ok by
hitting the healthcheck URL:

```bash
  curl localhost:50300/admin/healthcheck
```

## Managing Certificates for the IDAP PKI

In development mode, there is no need for key management. For the live service
we need to run the key rotation process to update certificates when they are
due to expire:

https://www.docs.verify.service.gov.uk/maintain-your-connection/rotate-keys/

More on this to follow once we move towards setting Verify up on staging and
production.
