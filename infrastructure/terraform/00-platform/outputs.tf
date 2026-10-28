output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "service_plan_name" {
  value = azurerm_service_plan.main.name
}

output "sql_server_name" {
  value = azurerm_mssql_server.main.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.main.name
}

