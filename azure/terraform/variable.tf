# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
# variable "mandatory_variable" {
#   type        = string
#   description = "This is mandatory as there is no default declaration"
# }

variable "input_region" {
  type        = string
  description = "Location for all of the Azure resources "
}
variable "input_environment" {
  type        = string
  description = "Which environmnet is being built, Dev, Test, Prod or Infradev"
}
variable "input_container_version" {
  type        = string
  description = "Which version of the container is to be built"
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

  #                            env is               "dev"                                          env is                      "test"                                            env is Production                    region is north eur                 "prod north Europe"                     else "prod West Europe"                   else "Dev"
  sub_id          = var.input_environment == "Development" ? "8655985a-2f87-44d7-a541-0be9a8c2779d" : var.input_environment == "Test" ? "e9299169-9666-4f15-9da9-5332680145af" : var.input_environment == "Production" ? (var.input_environment == "northeurope" ? "8655985a-2f87-44d7-a541-0be9a8c2779d" : "88bd392f-df19-458b-a100-22b4429060ed") : "8655985a-2f87-44d7-a541-0be9a8c2779d"
  tf_sa_container = var.input_environment == "Development" ? "s118d01devtfstate" : var.input_environment == "Test" ? "s118t01testtfstate" : var.input_environment == "Production" ? (var.input_environment == "northeurope" ? "s118p01northprodtfstate" : "s118p01westprodtfstate") : "s118d01devtfstate"
  rg_prefix       = var.input_environment == "Development" ? "s118d01" : var.input_environment == "Test" ? "s118t01" : var.input_environment == "Production" ? "s118p01" : "s118d01-infradev"
}
