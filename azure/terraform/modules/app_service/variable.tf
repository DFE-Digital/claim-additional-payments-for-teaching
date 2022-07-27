variable "app_rg_name" {
  type        = string
  description = "Resource group for the application"
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
variable "app_name" {
  type        = string
  description = "Identifier for review apps"
}
variable "db_host" {
  type        = string
  description = "FQDN of the postgres app database server"
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

locals {
  stash_port         = var.rg_prefix == "s118p01" ? "23888" : "17000"

  app_service_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "as") : format("%s-%s-%s", var.app_rg_name, var.app_name, "as")
  canonical_hostname = var.canonical_hostname != null ? var.canonical_hostname : "${local.app_service_name}.azurewebsites.net"
}
