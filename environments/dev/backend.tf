terraform {
  backend "azurerm" {
    resource_group_name  = "rg-platform-tfstate"
    storage_account_name = "stplatformtfstate009"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
