# CATALYST 8000v for Azure

# PARAMETERS

variable "config_file" {
  default = "../config.yaml"
}

locals {
  yaml_content = file(var.config_file)
  config       = yamldecode(local.yaml_content)
}

# CATALYST 8000v

resource "azurerm_linux_virtual_machine" "c8000v" {
  count                           = length(local.config.edge_instances)
  name                            = "${local.config.name}-${count.index}"
  resource_group_name             = azurerm_resource_group.instance.name
  location                        = azurerm_resource_group.instance.location
  size                            = local.config.azure.vm_size
  admin_username                  = local.config.edge_instances[count.index].admin_username
  admin_password                  = local.config.edge_instances[count.index].admin_password
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("../cloud_init.tftpl", local.config.edge_instances[count.index]))

  network_interface_ids = [
    azurerm_network_interface.network_transport[count.index].id,
    azurerm_network_interface.network_service[count.index].id,
  ]

  plan {
    name      = local.config.azure.image_sku   // This should match the SKU in source image reference
    product   = local.config.azure.image_offer // This should match the offer in source image reference
    publisher = "cisco"
  }

  os_disk {
    name                 = "${local.config.name}-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.config.azure.image_publisher
    offer     = local.config.azure.image_offer
    sku       = local.config.azure.image_sku
    version   = local.config.azure.image_version
  }

  tags = {
    Name = "${local.config.name}-${count.index}"
  }
}

# SAVE BOOTSTRAP CONFIG TO A FILE

resource "local_file" "custom_data_file" {
  count    = length(local.config.edge_instances)
  content  = templatefile("../cloud_init.tftpl", local.config.edge_instances[count.index])
  filename = "${path.module}/custom_data_content-${local.config.edge_instances[count.index].hostname}-${count.index}.txt"
}

# PUBLIC IP

resource "azurerm_public_ip" "transport_public_ip" {
  count               = length(local.config.edge_instances)
  name                = "${local.config.name}-public-ip-${count.index}"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${local.config.name}-public-ip-${count.index}"
  }
}

# INTERFACES

resource "azurerm_network_interface" "network_transport" {
  count               = length(local.config.edge_instances)
  name                = "${local.config.name}-nic-transport-${count.index}"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name

  ip_configuration {
    name                          = "${local.config.name}-transport-${count.index}"
    subnet_id                     = azurerm_subnet.transport.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.config.edge_instances[count.index].transport_ip
    public_ip_address_id          = azurerm_public_ip.transport_public_ip[count.index].id
  }

  tags = {
    Name = "${local.config.name}-interface-transport-${count.index}"
  }
}

resource "azurerm_network_interface" "network_service" {
  count               = length(local.config.edge_instances)
  name                = "${local.config.name}-nic-service-${count.index}"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name

  ip_configuration {
    name                          = "${local.config.name}-service-${count.index}"
    subnet_id                     = azurerm_subnet.service.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.config.edge_instances[count.index].service_ip
  }

  tags = {
    Name = "${local.config.name}-interface-service-${count.index}"
  }
}

# NETWORK INTERFACE SECURITY GROUP ASSOCIATIONS

resource "azurerm_network_interface_security_group_association" "transport_nsg_association" {
  count                     = length(local.config.edge_instances)
  network_interface_id      = azurerm_network_interface.network_transport[count.index].id
  network_security_group_id = azurerm_network_security_group.transport.id
}

resource "azurerm_network_interface_security_group_association" "service_nsg_association" {
  count                     = length(local.config.edge_instances)
  network_interface_id      = azurerm_network_interface.network_service[count.index].id
  network_security_group_id = azurerm_network_security_group.service.id
}
