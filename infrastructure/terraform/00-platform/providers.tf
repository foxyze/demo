terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.11"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                = var.subscription_id
  resource_providers_to_register = ["Microsoft.Web", "Microsoft.Sql"]
}
