
resource "azurerm_resource_group" "instance" {
  name     = "${local.config.name}-rg"
  location = local.config.azure.location
}
