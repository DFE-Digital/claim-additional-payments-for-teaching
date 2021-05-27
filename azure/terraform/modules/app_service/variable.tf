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
variable "app_asp_id" {
  type        = string
  description = "App Service plan ID of the application service"
}
variable "input_container_version" {
  type        = string
  description = "Container version fed in from Release"
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
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
# variable "optional_variable" {
#   type        = list(any)
#   description = "Having a default declaration makes a parameter optional"
#   default     = []
# }

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

  verify_entity_id   = var.rg_prefix == "s118d01" ? "development.additional-teaching-payment.education.gov.uk" : var.rg_prefix == "s118t01" ? "test.additional-teaching-payment.education.gov.uk" : var.rg_prefix == "s118p01" ? "www.claim-additional-teaching-payment.service.gov.uk" : "development.additional-teaching-payment.education.gov.uk"
  verify_environment = var.rg_prefix == "s118d01" ? "DEVELOPMENT" : var.rg_prefix == "s118t01" ? "INTEGRATION" : var.rg_prefix == "s118p01" ? "PRODUCTION" : "INFRA_DEV"
  environment        = var.rg_prefix == "s118d01" ? "development" : var.rg_prefix == "s118t01" ? "test" : var.rg_prefix == "s118p01" ? "production" : "infradev"
  stash_port         = var.rg_prefix == "s118p01" ? "23888" : "17000"

}


