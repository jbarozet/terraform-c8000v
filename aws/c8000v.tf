# Create NICs

# locals {
#   config = yamldecode(file("${path.module}/config.yaml"))
# }

variable "config_file" {
  default = "../config.yaml"
}

locals {
  yaml_content = file(var.config_file)
  config       = yamldecode(local.yaml_content)
}



# CATALYST 8000v

resource "aws_instance" "c8000v" {
  ami               = local.config.aws.image_id
  instance_type     = local.config.aws.instance_type
  availability_zone = local.config.aws.availability_zone
  # user_data         = file("playbooks/cloudinit/sdwanlab-edge-1")
  # user_data = file(local.config.edge_instances[0].hostname)
  user_data = templatefile("../cloud_init.tftpl",
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

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.network_transport.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.network_service.id
  }

  tags = {
    Name = "${local.config.name}"
  }

}

# Save user_data content to a file
resource "local_file" "user_data_file" {
  content  = templatefile("../cloud_init.tftpl", local.config.edge_instances[0])
  filename = "${path.module}/user_data_content.txt"
}

# PUBLIC IP

resource "aws_eip" "c8000v_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.network_transport.id
  associate_with_private_ip = tolist(aws_network_interface.network_transport.private_ips)[0]
  depends_on                = [aws_instance.c8000v]
  tags = {
    Name = "${local.config.name}-eip"
  }
}
