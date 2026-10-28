locals {
  suffix = substr(var.subscription_id, 0, 8)
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}"
  location = var.location
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "P0v3"
}

resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.project}-${local.suffix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "main" {
  name                        = "sqldb-${var.project}"
  server_id                   = azurerm_mssql_server.main.id
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
}

resource "azurerm_role_assignment" "deployer" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Website Contributor"
  principal_id         = var.deployer_sp_object_id
  principal_type       = "ServicePrincipal"
}

