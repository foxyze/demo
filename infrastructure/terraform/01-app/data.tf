data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_service_plan" "main" {
  name                = var.service_plan_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_mssql_server" "main" {
  name                = var.sql_server_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_mssql_database" "main" {
  name      = var.sql_database_name
  server_id = data.azurerm_mssql_server.main.id
}
