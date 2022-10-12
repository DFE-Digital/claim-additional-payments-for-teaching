variable "input_container_version" {
  type        = string
  description = "Which version of the container is to be built"
}
variable "rg_prefix" {
  type        = string
  description = "Resource group prefix"
}

variable "environment" {
  type        = string
  description = "Name of the application environment"
  default     = null
}

variable "env_tag" {
  type        = string
  description = "Standard Environment CIP tag"
  default     = null
}

variable "canonical_hostname" {
  type        = string
  description = "External domain name for the app service"
  default     = null
}

variable "create_database" {
  type        = bool
  description = "Create database via this terraform as opposed to the infrastructure terraform"
  default     = false
}

variable "bypass_dfe_sign_in" {
  type        = bool
  description = "Bypass DFE Sign-In authentication and use a default role"
  default     = false
}

variable "pr_number" {
  type        = string
  description = "Pull Request Number for Review App"
  default     = null
}

variable "suppress_dfe_analytics_init" {
  type        = string
  description = "Stop DfE-analytics from booting"
  default     = null
}

variable "enable_basic_auth" {
  type        = bool
  description = "Enable basic HTTP authentication"
  default     = false
}

locals {
  app_name = var.pr_number == null ? null : "pr-${var.pr_number}"
  db_name         = local.app_name == null ? var.environment : "${var.environment}-${local.app_name}"
  create_db_list  = var.create_database ? [local.db_name] : []
  app_rg_name = format("%s-%s", var.rg_prefix, "app")
  tags = {
    "Environment"      = var.env_tag
    "Parent Business"  = "Teacher Training and Qualifications"
    "Portfolio"        = "Early Years and Schools Group"
    "Product"          = "Claim Additional Payments for teaching"
    "Service"          = "Teacher services"
    "Service Line"     = "Teaching Workforce"
    "Service Offering" = "Claim Additional Payments (for teaching)"
  }
  input_region = "westeurope"
}
