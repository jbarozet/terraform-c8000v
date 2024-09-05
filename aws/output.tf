
output "c8000v_eip" {
  value = aws_eip.c8000v_eip.public_ip
}

output "user_data_content" {
  value = templatefile("../cloud_init.tftpl",
    {
      hostname          = local.config.edge_instances[0].hostname
      uuid              = local.config.edge_instances[0].uuid
      otp               = local.config.edge_instances[0].otp
      site_id           = local.config.edge_instances[0].site_id
      system_ip         = local.config.edge_instances[0].system_ip
      organization_name = local.config.edge_instances[0].organization_name
      vbond             = local.config.edge_instances[0].vbond
      vbond_port        = local.config.edge_instances[0].vbond_port
      admin_username    = local.config.edge_instances[0].admin_username
      admin_password    = local.config.edge_instances[0].admin_password
  })
  sensitive = true
}
