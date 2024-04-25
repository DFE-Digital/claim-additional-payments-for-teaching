TERRAFILE_VERSION=0.8
ARM_TEMPLATE_TAG=1.1.10
RG_TAGS={"Product" : "Claim Additional Payments for teaching"}
REGION=UK South
SERVICE_NAME=claim-additional-payments-for-teaching
SERVICE_SHORT=capt
DOCKER_REPOSITORY=ghcr.io/dfe-digital/claim-additional-payments-for-teaching

help:
	@grep -E '^[a-zA-Z\._\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

review:
	$(if ${PR_NUMBER}, , $(error Missing environment variable "PR_NUMBER", Please specify the pull request id))
	$(eval APP_NAME=pr-${PR_NUMBER})
	$(eval AZ_SUBSCRIPTION=s118-teacherpaymentsservice-development)
	$(eval RESOURCE_GROUP_NAME=s118d02-review-tfbackend)
	$(eval STORAGE_ACCOUNT_NAME=s118d02reviewtfbackendsa)
	$(eval CONTAINER_NAME=s118d02conttfstate)
	$(eval DEPLOY_ENV=review)
	$(eval BACKEND_KEY=-backend-config=key=${APP_NAME}.tfstate)
	$(eval export TF_VAR_pr_number=${PR_NUMBER})

test:
	$(eval AZ_SUBSCRIPTION=s118-teacherpaymentsservice-test)
	$(eval RESOURCE_GROUP_NAME=s118t01-tfbackend)
	$(eval STORAGE_ACCOUNT_NAME=s118t01tfbackendsa)
	$(eval CONTAINER_NAME=s118t01conttfstate)
	$(eval DEPLOY_ENV=test)

production:
	$(eval AZ_SUBSCRIPTION=s118-teacherpaymentsservice-production)
	$(eval RESOURCE_GROUP_NAME=s118p01-tfbackend)
	$(eval STORAGE_ACCOUNT_NAME=s118p01tfbackendsa)
	$(eval CONTAINER_NAME=s118p01conttfstate)
	$(eval DEPLOY_ENV=production)

.PHONY: review_aks
review_aks: test-cluster
	$(if ${PR_NUMBER},,$(error Missing PR_NUMBER))
	$(eval ENVIRONMENT=review-${PR_NUMBER})
	$(eval export TF_VAR_environment=${ENVIRONMENT})
	$(eval include global_config/review.sh)

set-azure-account:
	az account set -s ${AZ_SUBSCRIPTION}

set-azure-account-aks:
	[ "${SKIP_AZURE_LOGIN}" != "true" ] && az account set -s ${AZURE_SUBSCRIPTION} || true

terraform-init: set-azure-account
	$(if $(IMAGE_TAG), , $(error Missing environment variable "IMAGE_TAG"))
	terraform -chdir=azure/terraform init -reconfigure -upgrade \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=container_name=${CONTAINER_NAME} \
		${BACKEND_KEY}

terraform-plan: terraform-init
	terraform -chdir=azure/terraform plan \
		-var="input_container_version=${IMAGE_TAG}" \
		-var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

terraform-apply: terraform-init
	terraform -chdir=azure/terraform apply \
		-var="input_container_version=${IMAGE_TAG}" \
		-var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

terraform-destroy: terraform-init
	terraform -chdir=azure/terraform destroy \
		-var="input_container_version=${IMAGE_TAG}" \
		-var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

composed-variables:
	$(eval RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg)
	$(eval KEYVAULT_NAMES='("${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-app-kv", "${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-inf-kv")')
	$(eval STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}${CONFIG_SHORT}tfsa)
	$(eval LOG_ANALYTICS_WORKSPACE_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-log)

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: composed-variables set-azure-account-aks
	$(if ${DISABLE_KEYVAULTS},, $(eval KV_ARG=keyVaultNames=${KEYVAULT_NAMES}))
	$(if ${ENABLE_KV_DIAGNOSTICS}, $(eval KV_DIAG_ARG=enableDiagnostics=${ENABLE_KV_DIAGNOSTICS} logAnalyticsWorkspaceName=${LOG_ANALYTICS_WORKSPACE_NAME}),)

	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "${REGION}" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_GROUP_NAME}" 'tags=${RG_TAGS}' \
		"tfStorageAccountName=${STORAGE_ACCOUNT_NAME}" "tfStorageContainerName=terraform-state" \
		${KV_ARG} \
		${KV_DIAG_ARG} \
		"enableKVPurgeProtection=${KV_PURGE_PROTECTION}" \
		${WHAT_IF}

deploy-arm-resources: arm-deployment ## Validate ARM resource deployment. Usage: make domains validate-arm-resources

validate-arm-resources: set-what-if arm-deployment ## Validate ARM resource deployment. Usage: make domains validate-arm-resources

test-cluster:
	$(eval CLUSTER_RESOURCE_GROUP_NAME=s189t01-tsc-ts-rg)
	$(eval CLUSTER_NAME=s189t01-tsc-test-aks)
