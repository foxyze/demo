resource "azurerm_app_service_custom_hostname_binding" "app" {
  count               = var.enable_custom_domain ? 1 : 0
  hostname            = var.custom_domain
  app_service_name    = azurerm_linux_web_app.main.name
  resource_group_name = data.azurerm_resource_group.main.name

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "app" {
  count                      = var.enable_custom_domain ? 1 : 0
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.app[0].id
}

resource "azurerm_app_service_certificate_binding" "app" {
  count               = var.enable_custom_domain ? 1 : 0
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app[0].id
  certificate_id      = azurerm_app_service_managed_certificate.app[0].id
  ssl_state           = "SniEnabled"
}
