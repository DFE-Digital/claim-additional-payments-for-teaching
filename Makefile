review:
	$(if $(APP_NAME), , $(error Missing environment variable "APP_NAME", Please specify a name for your review app))
	$(eval AZ_SUBSCRIPTION=s118-teacherpaymentsservice-development)
	$(eval RESOURCE_GROUP_NAME=s118d02-review-tfbackend)
	$(eval STORAGE_ACCOUNT_NAME=s118d02reviewtfbackendsa)
	$(eval CONTAINER_NAME=s118d02conttfstate)
	$(eval DEPLOY_ENV=review)
	$(eval BACKEND_KEY=-backend-config=key=${APP_NAME}.tfstate)
	$(eval export TF_VAR_app_name=${APP_NAME})

dev:
	$(eval AZ_SUBSCRIPTION=s118-teacherpaymentsservice-development)
	$(eval RESOURCE_GROUP_NAME=s118d01-tfbackend)
	$(eval STORAGE_ACCOUNT_NAME=s118d01tfbackendsa)
	$(eval CONTAINER_NAME=s118d01conttfstate)
	$(eval DEPLOY_ENV=development)

test:
	$(eval AZ_SUBSCRIPTION=s118-teacherpaymentsservice-test)
	$(eval RESOURCE_GROUP_NAME=s118t01-tfbackend)
	$(eval STORAGE_ACCOUNT_NAME=s118t01tfbackendsa)
	$(eval CONTAINER_NAME=s118t01conttfstate)
	$(eval DEPLOY_ENV=test)

production:az l
	$(eval STORAGE_ACCOUNT_NAME=s118p01tfbackendsa)
	$(eval CONTAINER_NAME=s118p01conttfstate)
	$(eval DEPLOY_ENV=production)

set-azure-account:
	az account set -s ${AZ_SUBSCRIPTION}

terraform-init: set-azure-account
	$(if $(IMAGE_TAG), , $(error Missing environment variable "IMAGE_TAG"))
	terraform -chdir=azure/terraform init -reconfigure -upgrade \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=container_name=${CONTAINER_NAME} \
		${BACKEND_KEY}

terraform-plan: terraform-init
	terraform -chdir=azure/terraform plan \
		-var="input_region=westeurope" -var="input_container_version=${IMAGE_TAG}" \
		-var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

terraform-apply: terraform-init
	terraform -chdir=azure/terraform apply \
		-var="input_region=westeurope" -var="input_container_version=${IMAGE_TAG}" \
		-var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

terraform-destroy: terraform-init
	terraform -chdir=azure/terraform destroy \
		-var="input_region=westeurope" -var="input_container_version=${IMAGE_TAG}" \
		-var-file workspace_variables/${DEPLOY_ENV}.tfvars.json
