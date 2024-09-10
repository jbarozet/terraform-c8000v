provider "azurerm" {
  features {}
  subscription_id = local.config.azure.subscription_id
  # tenant_id       = local.config.azure.tenant_id
}