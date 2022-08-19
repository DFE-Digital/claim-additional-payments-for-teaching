resource "azurerm_linux_web_app_slot" "app_as_slot" {
  name                = "staging"
  app_service_id      = azurerm_linux_web_app.app_as.id
  https_only          = true

  site_config {
    health_check_path = "/healthcheck"
    application_stack {
      docker_image = "${local.docker_registry}/dfedigital/teacher-payments-service"
      docker_image_tag = var.input_container_version
    }
  }

  app_settings = local.environment_variables

  tags = var.common_tags
}
