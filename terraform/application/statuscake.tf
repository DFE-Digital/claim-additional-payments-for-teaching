# TODO: Uncomment when needed then follow these steps: https://github.com/DFE-Digital/teacher-services-cloud/blob/main/documentation/onboard-service.md#configure-statuscake-credentials

# module "statuscake" {
#   count = var.enable_monitoring ? 1 : 0

#   source = "./vendor/modules/aks//monitoring/statuscake"

#   uptime_urls = compact([module.web_application.probe_url, var.external_url])
#   ssl_urls    = compact([var.external_url])

#   contact_groups = var.statuscake_contact_groups
# }
