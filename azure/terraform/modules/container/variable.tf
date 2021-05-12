# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
# variable "mandatory_variable" {
#   type        = string
#   description = "This is mandatory as there is no default declaration"
# }

variable "app_rg_name" {
  type        = string
  description = "Resource group for the application"
}
variable "projcore_network_prof" {
  type        = string
  description = "Project Core network profile"
}
variable "container_version" {
  type        = string
  description = "Specific version of the docker contaner"
}
variable "rg_prefix" {
  type        = string
  description = "The prefix to be used for all resources"
}
variable "rg_location" {
  type        = string
  description = "The location of the resource group and the resources"
}
variable "common_tags" {
  type        = map(string)
  description = "Map of the mandatory standard DfE tags"
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL CALCULATED
# ---------------------------------------------------------------------------------------------------------------------
# locals {
#   calculated_local_value = uuid()
# }

locals {
  # verify_entity_id = "development.additional-teaching-payment.education.gov.uk"
  # verify_entity_id   = "www.claim-additional-teaching-payment.service.gov.uk" 
  # verify_environment = "INTEGRATION"

  verify_entity_id   = var.rg_prefix == "s118d01" ? "development.additional-teaching-payment.education.gov.uk" : var.rg_prefix == "s118t01" ? "development.additional-teaching-payment.education.gov.uk" : var.rg_prefix == "s118p01" ? "www.claim-additional-teaching-payment.service.gov.uk" : "development.additional-teaching-payment.education.gov.uk"
  verify_environment = var.rg_prefix == "s118d01" ? "DEVELOPMENT" : var.rg_prefix == "s118t01" ? "INTEGRATION" : var.rg_prefix == "s118p01" ? "PRODUCTION" : "INFRA_DEV"
  environment        = var.rg_prefix == "s118d01" ? "development" : var.rg_prefix == "s118t01" ? "test" : var.rg_prefix == "s118p01" ? "production" : "infradev"
  stash_port         = var.rg_prefix == "s118p01" ? "23888" : "17000"

}
