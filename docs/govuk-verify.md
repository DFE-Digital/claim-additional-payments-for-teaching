# GOV.UK Verify Integration

A good place to start is to read the
[GOV.UK Verify technical documentation](https://www.docs.verify.service.gov.uk/#gov-uk-verify-technical-documentation).

## Getting support

The email address for Verify support is idasupport@digital.cabinet-office.gov.uk
(which goes through to Zendesk). There is also a #govuk-verify slack channel on
the ukgovernmentdigital.slack.com slack workspace.

## Environment variables

Verify integration requires certain environment variables be set:

```bash
GOVUK_VERIFY_VSP_HOST=http://URL.FOR.VSP:12345
```

## Running locally in development

GOV.UK Verify integration requires using a Verify Service Provider (VSP) to
handle SAML secure messaging.

By default, Foreman downloads and runs the VSP via `foreman start` in
development with sample data for LOA 2. You must have Java 11, or a long-term
supported version of Java 8 installed for this to run successfully. We recommend
[OpenJDK][openjdk].

You can check that the VSP is running ok by hitting the healthcheck URL:

```bash
curl localhost:50300/admin/healthcheck
```

## Managing Certificates for the IDAP PKI

### Local develoment

In local development mode, nothing needs to be done here.

### Live environments

#### Requesting certificates

For non-production (integration) environments (`development` and `test`) and
production environments (`production`), we need to request certificates from
Verify. The following will guide you though the process of generating and
enrolling certificate requests.

```bash
bin/request-vsp-certs <environment> <version>
```

Where `<environment>` is one of `development` or `production` (we reuse
`development` certs for the `test` environment) and `<version>` is an integer,
usually 1 higher than the version of the certificates currently in use.

When `bin/request-vsp-certs` refers to "enrolling" the requests, follow the
process detailed in the section "2. Submit certificate signing requests" in the
private Verify docs entitled "GOV.UK Verify Certification Process for Relying
Party Subscribers". You will be prompted for the challenge phrase you submitted
during that process.

When it's finished, the generated keys, CSRs, and the challenge phrase will be
automatically stored in the Key Vault on Azure matching the environment they
were generated for.

Integration certificates expire after 2 years, while production certificates
expire after 6 months. See the
[Verify docs for how to rotate keys](https://www.docs.verify.service.gov.uk/maintain-your-connection/rotate-keys/)
for more information. `bin/request-vsp-certs` will probably be helpful.

#### Importing certificates

Once we get certificates back from Verify, we want to store them in the Key
Vault alongside the keys and requests. Run the following to automate that
process.

```bash
bin/import-vsp-certs <environment> <version>
```

Where `<environment>` and `<version>` match the values used to generate the
certificate request above.

[openjdk]: https://adoptopenjdk.net/
