
# RESOURCE GROUP
# Azure requires a resource group to contain all resources
# Note that you'll need to adjust the local.config variables to use Azure-specific settings like
# location instead of availability_zone, and vnet_address_space for the overall network address space.

# VIRTUAL NETWORK
# Equivalent to AWS VPC


# SUBNETS

resource "azurerm_subnet" "transport" {
  name                 = "${local.config.name}-subnet-transport"
  resource_group_name  = azurerm_resource_group.instance.name
  virtual_network_name = azurerm_virtual_network.instance.name
  address_prefixes     = [local.config.azure.subnet_transport_prefix]
}

resource "azurerm_subnet" "service" {
  name                 = "${local.config.name}-subnet-service"
  resource_group_name  = azurerm_resource_group.instance.name
  virtual_network_name = azurerm_virtual_network.instance.name
  address_prefixes     = [local.config.azure.subnet_service_prefix]
}

# PUBLIC IP
# Required for the NAT Gateway

resource "azurerm_public_ip" "nat_gateway" {
  name                = "${local.config.name}-nat-gateway-ip"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT GATEWAY
# Equivalent to AWS Internet Gateway for outbound internet access

resource "azurerm_nat_gateway" "instance" {
  name                    = "${local.config.name}-nat-gateway"
  location                = azurerm_resource_group.instance.location
  resource_group_name     = azurerm_resource_group.instance.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

# Associate NAT Gateway with public IP

resource "azurerm_nat_gateway_public_ip_association" "instance" {
  nat_gateway_id       = azurerm_nat_gateway.instance.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

# Associate NAT Gateway with transport subnet

resource "azurerm_subnet_nat_gateway_association" "transport" {
  subnet_id      = azurerm_subnet.transport.id
  nat_gateway_id = azurerm_nat_gateway.instance.id
}

# ROUTE TABLE

resource "azurerm_route_table" "network_transport" {
  name                = "${local.config.name}-transport-rt"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

# ROUTE TABLE ASSOCIATION

resource "azurerm_subnet_route_table_association" "network_transport" {
  subnet_id      = azurerm_subnet.transport.id
  route_table_id = azurerm_route_table.network_transport.id
}