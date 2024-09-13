
# OUTPUT PARAMETERS

output "c8000_instances_details" {
  description = "Details of C8000v instances"
  value = [
    for i, instance in azurerm_linux_virtual_machine.c8000v : {
      name                 = instance.name
      transport_public_ip  = azurerm_public_ip.transport_public_ip[i].ip_address
      transport_private_ip = azurerm_network_interface.network_transport[i].private_ip_address
      service_private_ip   = azurerm_network_interface.network_service[i].private_ip_address
    }
  ]
}
