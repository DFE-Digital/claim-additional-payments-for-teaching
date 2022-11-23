# Deployment process

All of our infrastructure is hosted on DfE's Cloud Infrastructure Platform in
[Microsoft Azure][azure].

The setup is specified as [Infrastructure as Code][iac] using Terraform, stored
in the `azure` folder in the root of the project.

## Automated deployment

[Azure DevOps](https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service) is
responsible for automated infrastructure deployments, this is separate from the
deployment of a version of the application.

## Manual deployment

Automated deployment should always be the first option but it may be required to
deploy manually for troubleshooting.

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
the test or production environments. See
[Privileged Identity Management requests](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1192624202/Privileged+Identity+Management+requests)
for more.

### Deploying to an environment

The docker image must be already built. It may be required to create a pull
request to let the build process run. All the available image tags are listed on
DockerHub: https://hub.docker.com/r/dfedigital/teacher-payments-service/tags

- Verify changes: `make <environment> terraform-plan IMAGE_TAG=xyz`
- Apply changes: `make <environment> terraform-apply IMAGE_TAG=xyz`

[azure]: https://azure.microsoft.com/en-gb/
[iac]: https://en.wikipedia.org/wiki/Infrastructure_as_code
[arm]: https://azure.microsoft.com/en-gb/resources/templates/
[azure_portal]: https://portal.azure.com/
