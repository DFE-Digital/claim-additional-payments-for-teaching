# Deployment process

All of our infrastructure is hosted on DfE's Cloud Infrastructure Platform in
[Microsoft Azure][azure].

The setup is specified as [Infrastructure as Code][iac] using Terraform, stored
in the `azure` folder in the root of the project.

## Automated deployment

[Azure DevOps](https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service) is
responsible for automated infrastructure deployments, this is seperate from the
deployment of a version of the application.

## Manual deployment

Deployments of changes to the infrastructure are a lot less frequent than the
application so they can be triggered manually.

### Deploying to an environment

The same terraform templates are used to deploy to all three environments, all
three deployments are done via Azure DevOps and have approval gates for the two
higher environments.

### Requesting permissions to acess the infrastructure in higer environments

- In the [Azure Portal][azure_portal], navigate to Azure AD Privileged Identity
  Management.
- Click 'My Roles', then 'Azure Resource Roles'.
- Then click 'Eligible Roles' in the table, choose the role you want access to
  and click 'Activate'.
- You can then choose how long you want permissions for, enter the reason you
  need access and click the button marked 'Activate'.
- Everyone in the Managers group will then get an email saying you have
  requested permissions and will be able to grant your permissions.

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
