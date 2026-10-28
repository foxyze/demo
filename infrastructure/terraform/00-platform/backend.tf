terraform {
  backend "azurerm" {
    resource_group_name  = "rg-demo-tfstate"
    storage_account_name = "stdemotfc18e119c"
    container_name       = "tfstate"
    key                  = "00-platform.tfstate"
  }
}

