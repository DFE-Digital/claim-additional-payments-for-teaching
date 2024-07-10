variable "cluster" {
  description = "AKS cluster where this app is deployed. Either 'test' or 'production'"
}
variable "namespace" {
  description = "AKS namespace where this app is deployed"
}
variable "environment" {
  description = "Name of the deployed environment in AKS"
}
variable "azure_resource_prefix" {
  description = "Standard resource prefix. Usually s189t01 (test) or s189p01 (production)"
}
variable "config_short" {
  description = "Short name of the environment configuration, e.g. dv, st, pd..."
}
variable "service_name" {
  description = "Full name of the service. Lowercase and hyphen separated"
}
variable "service_short" {
  description = "Short name to identify the service. Up to 6 charcters."
}
variable "deploy_azure_backing_services" {
  default     = true
  description = "Deploy real Azure backing services like databases, as opposed to containers inside of AKS"
}
variable "enable_postgres_ssl" {
  default     = true
  description = "Enforce SSL connection from the client side"
}
variable "enable_postgres_backup_storage" {
  default     = false
  description = "Create a storage account to store database dumps"
}
variable "docker_image" {
  description = "Docker image full name to identify it in the registry. Includes docker registry, repository and tag e.g.: ghcr.io/dfe-digital/teacher-pay-calculator:673f6309fd0c907014f44d6732496ecd92a2bcd0"
}
variable "startup_command" {
  type = list(string)
}
variable "worker_command" {
  type = list(string)
}
variable "external_url" {
  default     = null
  description = "Healthcheck URL for StatusCake monitoring"
}
variable "statuscake_contact_groups" {
  default     = []
  description = "ID of the contact group in statuscake web UI"
}
variable "enable_monitoring" {
  default     = false
  description = "Enable monitoring and alerting"
}
variable "config" {
  type = string
}
variable "canonical_hostname" {
  type        = string
  description = "External domain name for the app service"
  default     = null
}
variable "web_replicas" {
  description = "Number of replicas of the web app"
  default     = 1
}

locals {
  postgres_ssl_mode       = var.enable_postgres_ssl ? "require" : "disable"
  canonical_hostname      = var.canonical_hostname != null ? var.canonical_hostname : "${var.service_name}-${var.environment}-web.test.teacherservices.cloud"
  app_env_values_from_yml = yamldecode(file("${path.module}/config/${var.config}_app_env.yml"))
  app_env_values          = merge(local.app_env_values_from_yml)
}
