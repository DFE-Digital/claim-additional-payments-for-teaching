module "statuscake" {
  count = var.enable_monitoring ? 1 : 0

  source = "./vendor/modules/aks//monitoring/statuscake"

  uptime_urls = compact([module.web_application.probe_url, var.external_url])
  ssl_urls    = compact([var.apex_url])

  contact_groups = var.statuscake_contact_groups

  heartbeat_names  = [local.heartbeat_check_name]
}
