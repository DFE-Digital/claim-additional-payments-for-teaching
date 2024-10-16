# Deployment process

This Rails app runs on the
[Teacher Services Cloud](https://github.com/DFE-Digital/teacher-services-cloud)
Kubernetes infrastructure in Azure.

All of our infrastructure is run on
[Teacher Services Cloud](https://github.com/DFE-Digital/teacher-services-cloud)
Kubernetes infrastructure in Azure.

The setup is specified as [Infrastructure as Code][iac] using Terraform, stored
in the `terraform` folder in the root of the project.

## Automated deployment

We use GitHub Actions to automate our deployments to both the test and
production environments. You can find the workflow
[here](../.github/workflows/build_and_deploy.yml).

## Manual deployment

Automated deployment should always be the first option but it may be required to
deploy manually for troubleshooting.

### Requesting permissions to access the infrastructure in production environments

- In the [Azure Portal][azure_portal], navigate to Azure AD Privileged Identity
  Management.
- Click 'My Roles', then 'Groups'.
- In the 'Eligible assignments' table, click 'Activate' on the
  `s189 SRTL production PIM` group.
- You can then choose how long you want permissions for, enter the reason you
  need access and click the button marked 'Activate'

You will need to carry out a Privileged Identity Management request to deploy to
the production environment. See
[Privileged Identity Management requests](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1192624202/Privileged+Identity+Management+requests)
for more.

### Deploying to an environment

The docker image must be already built. It may be required to create a pull
request to let the build process run. All the available image tags are listed in
the GitHub repository packages:
https://github.com/orgs/DFE-Digital/packages?repo_name=claim-additional-payments-for-teaching

- Verify changes:
  `make [production|test] terraform-plan IMAGE_TAG=xyz`
- Apply changes:
  `make [production|test] terraform-apply IMAGE_TAG=xyz`

[azure]: https://azure.microsoft.com/en-gb/
[iac]: https://en.wikipedia.org/wiki/Infrastructure_as_code
[arm]: https://azure.microsoft.com/en-gb/resources/templates/
[azure_portal]: https://portal.azure.com/
