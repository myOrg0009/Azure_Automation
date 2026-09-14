terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet" {
  source              = "../../modules/vnet"
  name                = "vnet-platform-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  subnet_name         = "subnet-aks"
  subnet_prefix       = "10.0.1.0/24"
  tags                = { environment = var.environment }
}

module "acr" {
  source              = "../../modules/acr"
  name                = var.acr_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Basic"
  tags                = { environment = var.environment }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-platform-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = { environment = var.environment }
}

module "aks" {
  source              = "../../modules/aks"
  name                = "aks-platform-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "platform-${var.environment}"
  node_count          = var.node_count
  subnet_id           = module.vnet.subnet_id
  acr_id              = module.acr.acr_id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.id
  admin_group_object_id = var.admin_group_object_id
  tags                = { environment = var.environment }
}
