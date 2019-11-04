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
[openjdk](https://adoptopenjdk.net/)

You can check that the VSP is running ok by hitting the healthcheck URL:

```bash
curl localhost:50300/admin/healthcheck
```

### How to complete the Verify user journey in local development

After beginning the Verify flow, you will be redirected to a URL which looks
something like
`https://compliance-tool-reference.ida.digital.cabinet-office.gov.uk/SAML2/SSO`,
and which will display a JSON object in your browser. To complete the Verify
flow from here:

1. Follow the `responseGeneratorLocation` URL from this JSON object.
2. This will give you another JSON object, which provides `executeUri` URLs
   which you can follow to simulate various Verify outcomes. For example, to
   simulate a successful Verify outcome, use the test case whose title at the
   time of writing is "Verified User On Service With Non Match Setting".

These steps are explained in more detail in the
[Verify documentation](https://www.docs.verify.service.gov.uk/get-started/set-up-successful-verification-journey/#run-the-identity-verified-response-scenario).

## Managing Certificates for the IDAP PKI

Two certificates are used one for signing and one for encryption.

The are separate certificates for non-production (integration) and production
environments

### Local development

In local development mode, nothing needs to be done.

### Live environments

Integration certificates expire after 2 years, while production certificates
expire after 6 months. See the
[Verify docs for how to rotate keys](https://www.docs.verify.service.gov.uk/maintain-your-connection/rotate-keys/)
for more information.

Pre-requisites:

- You are a requester, see this page on
  [confluence](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1116110992/Verify+Service+Provider)
- You have access to the Azure management portal for the project
- You have the
  [Azure cli installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- You have the code-base locally

#### Requesting certificates

For non-production (integration) environments (`development`) and production
environments (`production`), we need to request certificates from Verify. The
following will guide you though the process of generating, enrolling and
rotating certificates.

##### Create certificate signing requests (CSR)

Complete these steps for both signing and encryption certificates.

Access the Azure portal and locate the key vault for the environment you are
updating the certificates for.

https://portal.azure.com/

Note the version number of the latest set of certificates, keys, CSRs and
challenge phrase e.g. TeacherPayments`{ENV}`VspSaml `{TYPE}` `{VERSION_NUMBER}`,
where:

- `ENV` is the environment (either Dev or Prod)
- `TYPE` is the type of certificate (Signing or Encryption)
- `VERSION_NUMBER` is the version number

Run the request script with the next version number in the sequence:

```bash
bin/request-vsp-certs <environment> <version>
```

Once complete, the CSR, keys and challenge phrase are all added to your local
directory in `tmp/certs` and uploaded to the Azure Keyvault.

**Be mindful to delete these files once you are confident they have been
enrolled (see below).**

##### Enrol

Complete these steps for both signing and encryption certificates.

Open the following document:

<https://docs.google.com/document/d/1lH4b2uOn35rdzLAzW5I-_O9wG9NU8fTre8FaM0Y97L8/edit?pli=1#>

And go to the appropriate url for the environment you are enrolling the
certificates for, either integration or production.

- Choose ENROL
- Upload the CSR file
- Enter the details in the form:
  - Applicant Details: your name and the group email address
    (capt-dev@digital.education.gov.uk), ensure the email address is correct as
    this is where the certificate will be sent.
  - Certificate Profile: Select the type of certificate either SAML Signing or
    SAML Encryption, ensure this matches the CSR you are uploading
  - Challenge Phrase: the challenge phrase used above

Once submitted you will receive a confirmation email, the certificates will be
generated within 5 days and we be sent to the group email address.

##### Import

When you receive the certificates run the import script for both signing and
encryption certificates:

```bash
bin/import-vsp-certs <environment> <version>
```

Using the same environment and version as you set in the `request-vsp-certs`
script.

When prompted, paste the certificate body for the type of certificate (signing
or encryption) - be careful to note which type of certificate you are importing.

The script copies the certificates to the Azure Keyvault.

##### Rotate

The steps to actually rotate the keys varies between the two types of
certificate. See the
[Verify docs for this step](https://www.docs.verify.service.gov.uk/maintain-your-connection/rotate-keys/#rotate-your-encryption-and-signing-keys).

###### Signing key

Now that the signing key is stored in the Azure Keyvault, the next step gets the
application to use it:

- Send the GOVUK Verify team an email to
  idasupport+onboarding@digital.cabinet-office.gov.uk with the signing
  certificate letting them know you are rotating the signing key

Once you have a response that the certificate is deployed:

- Locate the `production.template.json` and/or `development.template.json` in
  `azure/app/parameters` for the environment you are updating
- Open the file and edit the `VSP.SAML_SIGNING_KEY` entry
- You'll see the `secret_name` matches the one in the Azure Keyvault with the
  old version number
- Update the version number, commit the changes and open a PR to get them merged
- The next deploy will update the keys. If updating production you will have to
  perform a release
- Let the GOVUK Verify team know the signing key has been rotated, and they will
  delete the old key

###### Encryption key

Now that the encryption key is stored in the Azure Keyvault, the next step gets
the application to use it:

- Locate the `production.template.json` and/or `development.template.json` in
  `azure/app/parameters` for the environment you are updating
- Open the file and edit the `VSP.SAML_SECONDARY_ENCRYPTION_KEY` entry
- The `VSP.SAML_SECONDARY_ENCRYPTION_KEY` entry will have a `value` of an empty
  string
- Create a new object in `VSP.SAML_SECONDARY_ENCRYPTION_KEY` that references
  your new certificate, for example:

  ```json
  "VSP.SAML_SECONDARY_ENCRYPTION_KEY": {
    "reference": {
      "keyVault": {
        "id": "${keyVaultId}"
      },
      "secretName": "TeacherPaymentsProdVspSamlEncryption3KeyBase64"
    }
  },
  ```

- Commit, review and merge this change. If updating production you will have to
  perform a release

At this point the service is able to use both the old and the new encryption
keys.

- Send the GOVUK Verify team an email to
  idasupport+onboarding@digital.cabinet-office.gov.uk with the encryption
  certificate letting them know we are rotating the encryption key

Once you have a response that the certificate is deployed, move on

- Move the object from `VSP.SAML_SECONDARY_ENCRYPTION_KEY` to
  `VSP.SAML_PRIMARY_ENCRYPTION_KEY`
- Set the `VSP.SAML_SECONDARY_ENCRYPTION_KEY` value to an empty string:

  ```json
      "VSP.SAML_SECONDARY_ENCRYPTION_KEY": {
      "value": ""
      },
  ```

- commit, review and merge this change, if updating production you will have to
  perform a release

#### Clean up

Confirm the Keyvault contains all of the generated keys and secrets. If so,
remove any copies of the files from `tmp/certs`.
