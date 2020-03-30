# GOV.UK Verify – Rotating keys and certificates

The Verify Service Provider (VSP) uses two key/certificate pairs to encrypt
requests and decrypt responses from GOV.UK Verify. These need to be rotated
regularly:

- Production every 6 months
- Non-production (integration) every 2 years

The process is slightly different for each type of key/certificate so the steps
below should be followed carefully and in order.

These steps are based on the
[GOV.UK Verify documented process for rotating](https://www.docs.verify.service.gov.uk/rotating-your-keys-and-certificates/#rotating-your-keys-and-certificates),
but adapted for our service, release process, and the Azure platform.

## Pre-requisites for rotating the keys and certificates

To perform this task, you will need:

- Access to the
  [GOV.UK Verify Manage certificates service](https://www.admin.verify.service.gov.uk)
- Access to the Azure management portal for the project
- The
  [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- The codebase cloned locally

Speak to the product manager if you need access to the GOV.UK Manage
certificates service or the Azure portal.

The following instructions are broadly the same whether performing the rotation
on production or development. Replace occurrences of `<environment>` with either
`production` or `development` as appropriate.

## Step 1. Add your local IP address to the Azure key vault firewall

The scripts we are about to run will access and update the key vault on Azure,
which is protected by a firewall. Before you can access the key vault you will
need to add your IP to the allow list:

- Make a PIM request to get permission if updating the production environment
- Navigate to the key vault in the Azure Portal
- Go to "Firewalls and virtual networks" under "Networking"
- Add your IP under "Firewall" and click "Save"

## Step 2. Generate new keys/certificates and import them to Azure

New key and certificate pairs need to be generated for signing and encryption.
Most of this process is automated with a script. First we need to find out the
current version number so we can generate the next one.

Look in `azure/app/parameters/<environment>.template.json` and look for both the
`VSP.SAML_SIGNING_KEY` and `VSP.SAML_PRIMARY_ENCRYPTION_KEY` configurations.
These will have `"name"` values in a format like:

"TeacherPayments{ENV}VspSaml{TYPE}{VERSION_NUMBER}KeyBase64"

where:

- `ENV` is the environment (either "Dev" or "Prod")
- `TYPE` is the type of certificate ("Signing" or "Encryption")
- `VERSION_NUMBER` is the current version number

Both parameters should share the same `VERSION_NUMBER`.

To generate a new set of keys and certificates, run the following command with
the name of the environment and the **next number** in the sequence:

```bash
bin/generate-vsp-keys-and-certs <environment> <VERSION_NUMBER+1>
```

This will generate new keys and self-signed certificates in `tmp/certs` and
upload them to the Azure key vault.

(Note that this script is written such that if you pass it the current version
number, instead of generating and overwriting the existing keys and certificates
it will download the existing keys and certificates to the tmp directory. This
may be useful if you need to access and re-upload the existing certificates.)

With new keys and certificates generated it is time to get them installed. They
need to be done in two phases, starting with the encryption key and certificate.

## Step 3. Add the new encryption key to the VSP configuration

To rotate the keys/certs without downtime the new encryption key needs to be
added to the VSP as a secondary encryption key. This will require a release:

Edit `azure/app/parameters/<environment>.template.json` and update
`VSP.SAML_SECONDARY_ENCRYPTION_KEY` with the newly created key, for example:

```json
"VSP.SAML_SECONDARY_ENCRYPTION_KEY": {
  "reference": {
    "keyVault": {
      "id": "${keyVaultId}"
    },
    "secretName": "TeacherPayments<Dev|Prod>VspSamlEncryption<VERSION_NUMBER+1>KeyBase64"
  }
},
```

Paying attention to make sure the `secretName` has the correct environment and
version number.

Commit, review and merge this change. Perform a release if it's the production
keys/certificates that are being updated.

Once this change has been shipped the VSP will be configured to use both the new
and old keys to decrypt SAML message responses from GOV.UK Verify.

## Step 4. Replace the encryption certificate on GOV.UK Verify with the new one

Now that the VSP is configured with both the old and the new encryption key, the
certificate on GOV.UK Verify can be replaced. Go to the
[GOV.UK Verify Manage certificates service](https://www.admin.verify.service.gov.uk)
and replace the encryption certificate with the newly created one. It will be in
`tmp/certs/` with a name like:

`TeacherPayments<Dev|Prod>VspSamlEncryption<VERSION_NUMBER+1>.crt`

This will start a deploy of GOV.UK Verify to load the new certificate. GOV.UK
Verify will send an email when this has completed successfully. At this point
GOV.UK Verify will be using the new certificate to encrypt responses.

To confirm the VSP is correctly configured and can decrypt these responses start
a claim and complete the GOV.UK Verify process. In production you will need to
use real details when completing GOV.UK Verify. In development you can use the
test credentials documented in the
[service’s Confluence space](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1106444353/GOV.UK+Verify).

With the encryption key and certificate dealt with, now it's time to rotate the
signing key and certificate.

## Step 5. Add the new signing certificate to GOV.UK Verify

With the encryption key/certificate, first the VSP was updated to use both the
old and new key, then the certificate was replaced on GOV.UK Verify. With the
signing key/certificate, the reverse is required: GOV.UK Verify must be updated
to handle both the old and the new certificates; then the VSP can be updated
with the new key.

On the
[GOV.UK Verify Manage certificates service](https://www.admin.verify.service.gov.uk)
add the new signing certificate, which will be in `tmp/certs` with a name like:

`TeacherPayments<Dev|Prod>VspSamlSigning<VERSION_NUMBER+1>.crt`

As with the encryption certificate, this will trigger a deploy of GOV.UK Verify
and an email will confirm when this has completed successfully. At this point
GOV.UK Verify is configured to accept requests signed with both the old and the
new key.

## Step 6. Replace the signing key in the VSP configuration with the new key

Now that GOV.UK Verify has the new signing certificate, the VSP can be updated
to sign requests with the new signing key.

Edit `azure/app/parameters/<environment>.template.json` and update the
`VSP.SAML_SIGNING_KEY` entry and update the value to match the name of the new
signing key. It will in `tmp/certs` with a name like:

`TeacherPayments<Dev|Prod>VspSamlSigning<VERSION_NUMBER+1>.key`

Commit, review and merge this change. Perform a release if it's the production
keys/certificates that are being updated.

Once this change has been shipped the VSP will be configured to sign requests
with the new signing key.

To confirm everything is correctly configured start a claim and complete GOV.UK
Verify process.

## Step 7. Clean up – remove the old encryption key from the VSP configuration

Edit `azure/app/parameters/<environment>.template.json` and move the object from
the `VSP.SAML_SECONDARY_ENCRYPTION_KEY` to `VSP.SAML_PRIMARY_ENCRYPTION_KEY`.

Set the `VSP.SAML_SECONDARY_ENCRYPTION_KEY` value to an empty string:

```json
    "VSP.SAML_SECONDARY_ENCRYPTION_KEY": {
    "value": ""
    },
```

Commit, review and merge this change. Perform a release if it's the production
keys/certificates that are being updated.

## Step 8. Clean up – delete the old signing certificate from GOV.UK Verify

On the
[GOV.UK Verify Manage certificates service](https://www.admin.verify.service.gov.uk)
remove the old signing certificate and perform a test by starting a claim and
completing the GOV.UK Verify process and confirm everything is working
end-to-end.

## Step 9. Clean up – delete the local copies of the keys and certificates

Make sure to securely delete the copies of the keys and certificates stored in
`tmp/certs`.

## Step 10. Clean up – remove your local IP address from the Azure key vault firewall

The key vault firewall should aumatically get reset on a redeploy, but double
check to be sure:

- Navigate to the key vault in the Azure Portal
- Go to "Firewalls and virtual networks" under "Networking"
- Delete your IP address from the list of allowed IPs
