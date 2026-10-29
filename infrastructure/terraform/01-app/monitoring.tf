resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
}

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.project}"
  resource_group_name = data.azurerm_resource_group.main.name
  short_name          = var.project

  email_receiver {
    name          = "ops"
    email_address = var.alert_email
  }
}

locals {
  sql_alerts = {
    cpu      = { metric = "cpu_percent", aggregation = "Average", threshold = 80, skip = false }
    storage  = { metric = "storage_percent", aggregation = "Maximum", threshold = 80, skip = false }
    deadlock = { metric = "deadlock", aggregation = "Total", threshold = 0, skip = true }
  }
}

resource "azurerm_monitor_metric_alert" "sql" {
  for_each            = local.sql_alerts
  name                = "alert-sql-${each.key}"
  resource_group_name = data.azurerm_resource_group.main.name
  scopes              = [data.azurerm_mssql_database.main.id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = each.value.metric
    aggregation      = each.value.aggregation
    operator         = "GreaterThan"
    threshold        = each.value.threshold

    skip_metric_validation = each.value.skip
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
