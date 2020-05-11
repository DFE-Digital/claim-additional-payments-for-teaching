# Deployment process

All of our infrastructure is hosted on DfE's Cloud Infrastructure Platform in
[Microsoft Azure][azure].

The setup is specified as [Infrastructure as Code][iac] using [Azure Resource
Mananger (ARM) Templates][arm], stored in the `azure` folder in the root of the
project.

Many of the ARM templates build on top of building blocks already developed by
the [Becoming A Teacher team][building_blocks].

## Automated deployment

[Azure DevOps](https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service) is
responsible for automated infrastructure deployments as part of deploying a
version of the app.

## Manual deployment

It should rarely (or never) happen, but if manual deployment is required, the
following will help.

### Deploying to development

There is a script that deploys the ARM templates to the environment that can be
run like so:

```bash
bin/azure-deploy development
```

This creates (if one does not already exist) a KeyVault (where all application
secrets are added) and applies any new changes to the Azure CIP infrastructure.

### Deploying to production or test

Before deploying to production or test, you need to be added to the production
or test subscription as a contributor. These permissions are transient and
expire after a maximum of 8 hours, so usually this will be the first thing you
do when preparing for a deploy.

#### Requesting permissions

- In the [Azure Portal][azure_portal], navigate to Azure AD Privileged Identity
  Management.
- Click 'My Roles', then 'Azure Resource Roles'.
- Then click 'Eligible Roles' in the table, choose the role you want access to
  and click 'Activate'.
- You can then choose how long you want permissions for, enter the reason you
  need access and click the button marked 'Activate'.
- Everyone in the Managers group will then get an email saying you have
  requested permissions and will be able to grant your permissions.

#### Deploying

Once you have permissions, you'll recieve an email from Azure letting you know
the permissions have been granted, and you can run your command like so:

```bash
bin/azure-deploy <environment>
```

Where `<environment>` is the environment you want to deploy to.

This script runs in the same way as the development deployment. Once the script
has finished running the changes will be applied to your environment!

## Testing deployment

If you want to test changes to infrastructure with minimal impact to existing
environments, you can deploy to the test environment:

```bash
bin/azure-deploy test
```

You will need to carry out a Privileged Identity Management request to deploy to
the test environment. See
[Privileged Identity Management requests](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1192624202/Privileged+Identity+Management+requests)
for more.

Deployments rely on having web access to the current version of the Git
repository (they attempt to fetch the current commit hash from GitHub). To test
changes, you'll need to push them up to GitHub in a work in progress commit
before running `bin/azure-deploy`. **Beware of accidentally pushing up secrets
when doing this.**

[azure]: https://azure.microsoft.com/en-gb/
[iac]: https://en.wikipedia.org/wiki/Infrastructure_as_code
[arm]: https://azure.microsoft.com/en-gb/resources/templates/
[building_blocks]: https://github.com/DFE-Digital/bat-platform-building-blocks
[azure_portal]: https://portal.azure.com/
