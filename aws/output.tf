
output "c8000v_name0" {
  value = local.config.edge_instances[0].hostname
}
output "c8000v_name1" {
  value = local.config.edge_instances[1].hostname
}

output "c8000v_eip0" {
  value = aws_eip.c8000v_eip[0].public_ip
}
output "c8000v_eip1" {
  value = aws_eip.c8000v_eip[1].public_ip
}

