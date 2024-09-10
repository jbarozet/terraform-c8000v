# VNET DEFINITION
resource "azurerm_virtual_network" "instance" {
  name                = "${local.config.name}-vnet"
  address_space       = [local.config.azure.address_space]
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name

  tags = {
    Name = "${local.config.name}-vnet"
  }

}
