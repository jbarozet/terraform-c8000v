
# output "c8000v_name0" {
#   value = local.config.edge_instances[0].hostname
# }
# output "c8000v_name1" {
#   value = local.config.edge_instances[1].hostname
# }

# output "c8000v_eip0" {
#   value = aws_eip.c8000v_eip[0].public_ip
# }
# output "c8000v_eip1" {
#   value = aws_eip.c8000v_eip[1].public_ip
# }

# output "c8000v_names" {
#   value       = [for instance in local.config.edge_instances : instance.hostname]
#   description = "Hostnames of all C8000v instances"
# }

# output "c8000v_eips" {
#   value       = aws_eip.c8000v_eip[*].public_ip
#   description = "Public IP addresses of all C8000v instances"
# }

output "c8000v_instance_details" {
  value = [
    for i, instance in aws_instance.c8000v : {
      instance_id          = instance.id
      hostname             = instance.tags["Name"]
      transport_public_ip  = aws_eip.c8000v_eip[i].public_ip
      transport_private_ip = aws_network_interface.network_transport[i].private_ips
      service_private_ip   = aws_network_interface.network_service[i].private_ips
    }
  ]
  description = "Detailed information for all C8000v instances"
}
