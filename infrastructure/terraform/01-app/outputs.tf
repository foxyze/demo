output "custom_domain_verification_id" {
  value     = azurerm_linux_web_app.main.custom_domain_verification_id
  sensitive = true
}

output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "app_name" {
  value = azurerm_linux_web_app.main.name
}

output "slot_name" {
  value = azurerm_linux_web_app_slot.preprod.name
}

output "default_hostname" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "slot_hostname" {
  value = azurerm_linux_web_app_slot.preprod.default_hostname
}

output "custom_domain" {
  value = var.enable_custom_domain ? var.custom_domain : null
}
