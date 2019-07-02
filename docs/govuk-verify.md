# GOV.UK Verify Integration

A good place to start is to read the [GOV.UK Verify technical documentation](https://www.docs.verify.service.gov.uk/#gov-uk-verify-technical-documentation).

## Getting support

The email address for Verify support is idasupport@digital.cabinet-office.gov.uk
(which goes through to Zendesk). There is also a #govuk-verify slack channel
on the ukgovernmentdigital.slack.com slack workspace.

## Environment variables

Verify integration requires certain environment variables be set:

```bash
  GOVUK_VERIFY_VSP_HOST=http://URL.FOR.VSP:12345
```

## Running locally in development

Currently GOV.UK Verify integration is under active development and can be
enabled by setting an environment variable in your `.env` file:

```bash
  GOVUK_VERIFY_ENABLED=1
```

GOV.UK Verify integration requires using a Verify Service Provider (VSP)
to handle SAML secure messaging.

By default, Foreman downloads and runs the VSP via `foreman start` in development
with sample data for LOA 2. You must have Java 11, or a long-term supported version
of Java 8 installed for this to run successfully. We recommend [OpenJDK][openjdk].

You can check that the VSP is running ok by hitting the healthcheck URL:

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

[openjdk]: https://adoptopenjdk.net/
