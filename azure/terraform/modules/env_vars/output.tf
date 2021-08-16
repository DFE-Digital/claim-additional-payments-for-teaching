output "common_tags" {
  value = merge({
    "Environment"      = local.env_tag
    "Parent Business"  = "Teacher Training and Qualifications"
    "Portfolio"        = "Early Years and Schools Group"
    "Product"          = "Claim Additional Payments for teaching"
    "Service"          = "Teacher services"
    "Service Line"     = "Teaching Workforce"
    "Service Offering" = "Claim Additional Payments (for teaching)"
    # "CostCentre"       = "DataCollections"    
  }, var.std_tags)
}

output "rg_prefix" { value = local.rg_prefix }

# output "container_version" { value = local.container_version }
