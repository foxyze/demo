locals {
  suffix = substr(var.subscription_id, 0, 8)
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project}-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = data.azurerm_service_plan.main.id
  https_only          = true

  site_config {
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 10

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Production"
  }

  connection_string {
    name  = "piranha"
    type  = "SQLAzure"
    value = "Server=tcp:${data.azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${data.azurerm_mssql_database.main.name};User ID=${data.azurerm_mssql_server.main.administrator_login};Password=${var.sql_admin_password};Encrypt=True;"
  }

    lifecycle {
    ignore_changes = [virtual_network_subnet_id]
  }

}
