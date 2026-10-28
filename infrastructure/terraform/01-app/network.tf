resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "integration" {
  name                 = "snet-integration"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
  service_endpoint {
    service = "Microsoft.Sql"
  }

  delegation {
    name = "web"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = azurerm_subnet.integration.id
}

resource "azurerm_mssql_virtual_network_rule" "app" {
  name      = "allow-app-integration"
  server_id = data.azurerm_mssql_server.main.id
  subnet_id = azurerm_subnet.integration.id
}
