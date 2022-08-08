variable "app_rg_name" {
  type        = string
  description = "Resource group for the application"
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
variable "app_name" {
  type        = string
  description = "Identifier for review apps"
}
variable "db_host" {
  type        = string
  description = "Database hostname"
}
variable "db_name" {
  type        = string
  description = "Name of the postgres app database"
}
variable "db_admin_username" {
  type        = string
  description = "Username of the postgres app database server administrator"
}
variable "environment" {
  type        = string
  description = "Name of the application environment"
  default     = null
}
variable "canonical_hostname" {
  type        = string
  description = "External domain name for the app service"
  default     = null
}
variable "bypass_dfe_sign_in" {
  type        = bool
  description = "Bypass DFE Sign-In authentication and use a default role"
}

locals {
  stash_port         = var.rg_prefix == "s118p01" ? "23888" : "17000"

  cont_grp_01_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "worker-aci") : format("%s-%s-%s", var.app_rg_name, var.app_name, "worker-aci")
  cont_grp_02_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "migration-runner-aci") : format("%s-%s-%s", var.app_rg_name, var.app_name, "migration-runner-aci")
  cont_01_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "worker-container") : format("%s-%s-%s", var.app_rg_name, var.app_name, "worker-container")
  cont_02_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "migration-runner-container") : format("%s-%s-%s", var.app_rg_name, var.app_name, "migration-runner-container")

  app_service_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "as") : format("%s-%s-%s", var.app_rg_name, var.app_name, "as")
  canonical_hostname = var.canonical_hostname != null ? var.canonical_hostname : "${local.app_service_name}.azurewebsites.net"
}
