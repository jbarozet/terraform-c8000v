
output "c8000v_name" {
  value = local.config.edge_instances[0].hostname
}

output "c8000v_eip" {
  value = aws_eip.c8000v_eip.public_ip
}

