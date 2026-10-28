locals {
  suffix = substr(var.subscription_id, 0, 8)

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Production"
  }

  sql_connection_string = "Server=tcp:${data.azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${data.azurerm_mssql_database.main.name};User ID=${data.azurerm_mssql_server.main.administrator_login};Password=${var.sql_admin_password};Encrypt=True;"
}

resource "azurerm_linux_web_app" "main" {
  name                          = "app-${var.project}-${local.suffix}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  service_plan_id               = data.azurerm_service_plan.main.id
  https_only                    = true
  public_network_access_enabled = true

  site_config {
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 10
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Allow"

    dynamic "ip_restriction" {
      for_each = var.allowed_ips
      content {
        name       = "allow-${ip_restriction.key}"
        ip_address = ip_restriction.value
        action     = "Allow"
        priority   = 100 + ip_restriction.key
      }
    }

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = local.app_settings

  connection_string {
    name  = "piranha"
    type  = "SQLAzure"
    value = local.sql_connection_string
  }

  sticky_settings {
    connection_string_names = ["piranha"]
    app_setting_names       = ["APPLICATIONINSIGHTS_CONNECTION_STRING"]
  }

  lifecycle {
    ignore_changes = [virtual_network_subnet_id]
  }
}

resource "azurerm_linux_web_app_slot" "preprod" {
  name                          = "preprod"
  app_service_id                = azurerm_linux_web_app.main.id
  https_only                    = true
  public_network_access_enabled = true

  site_config {
    health_check_path                 = "/"
    health_check_eviction_time_in_min = 10
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Allow"

    dynamic "ip_restriction" {
      for_each = var.allowed_ips
      content {
        name       = "allow-${ip_restriction.key}"
        ip_address = ip_restriction.value
        action     = "Allow"
        priority   = 100 + ip_restriction.key
      }
    }

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = local.app_settings

  connection_string {
    name  = "piranha"
    type  = "SQLAzure"
    value = local.sql_connection_string
  }

  lifecycle {
    ignore_changes = [virtual_network_subnet_id]
  }
}
