# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
# variable "mandatory_variable" {
#   type        = string
#   description = "This is mandatory as there is no default declaration"
# }

variable "input_environment" {}


# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
# variable "optional_variable" {
#   type        = list(any)
#   description = "Having a default declaration makes a parameter optional"
#   default     = []
# }

variable "std_tags" {
  type    = map(string)
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL CALCULATED
# ---------------------------------------------------------------------------------------------------------------------
# locals {
#   calculated_local_value = uuid()
# }

locals {
  rg_prefix         = var.input_environment == "Development" ? "s118d01" : var.input_environment == "Test" ? "s118t01" : var.input_environment == "Production" ? "s118p01" : "s118d01-infradev"
  env_tag           = var.input_environment == "Development" ? "Dev" : var.input_environment == "Test" ? "Test" : var.input_environment == "Production" ? "Prod" : "Dev"
  # container_version = var.input_environment == "Development" ? "20210420.8" : var.input_environment == "Test" ? "20210331.2" : var.input_environment == "Production" ? "20210201.3" : "20210201.3"
}
