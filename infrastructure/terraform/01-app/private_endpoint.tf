resource "azurerm_private_dns_zone" "web" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "web" {
  name                = "link-${azurerm_virtual_network.main.name}"
  private_dns_zone_id = azurerm_private_dns_zone.web.id
  virtual_network_id  = azurerm_virtual_network.main.id
}

resource "azurerm_private_endpoint" "app" {
  name                = "pe-${azurerm_linux_web_app.main.name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "app"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.web.id]
  }
}

resource "azurerm_private_endpoint" "preprod" {
  name                = "pe-${azurerm_linux_web_app.main.name}-preprod"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "preprod"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites-preprod"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.web.id]
  }
}
