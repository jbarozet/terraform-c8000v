# CATALYST 8000v

# PARAMETERS

variable "config_file" {
  default = "../config.yaml"
}

locals {
  yaml_content = file(var.config_file)
  config       = yamldecode(local.yaml_content)
}

# CATALYST 8000v

resource "aws_instance" "c8000v" {
  count             = length(local.config.edge_instances)
  ami               = local.config.aws.image_id
  instance_type     = local.config.aws.instance_type
  availability_zone = local.config.aws.availability_zone
  user_data         = templatefile("../cloud_init.tftpl", local.config.edge_instances[count.index])

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.network_transport[count.index].id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.network_service[count.index].id
  }

  tags = {
    Name = "${local.config.name}-${count.index}"
  }

}

# Save user_data content to a file
resource "local_file" "user_data_file" {
  count    = length(local.config.edge_instances)
  content  = templatefile("../cloud_init.tftpl", local.config.edge_instances[count.index])
  filename = "${path.module}/user_data_content-${local.config.edge_instances[count.index].hostname}-${count.index}.txt"
}

# INTERFACES

resource "aws_network_interface" "network_transport" {
  count    = length(local.config.edge_instances)
  subnet_id         = aws_subnet.transport.id
  security_groups   = [aws_security_group.transport.id]
  private_ips       = [local.config.edge_instances[count.index].transport_ip]
  source_dest_check = false
  description       = "transport"

  tags = {
    Name = "${local.config.name}-interface-transport-${count.index}"
  }
}

resource "aws_network_interface" "network_service" {
  count             = length(local.config.edge_instances)
  subnet_id         = aws_subnet.service.id
  security_groups   = [aws_security_group.transport.id]
  private_ips       = [local.config.edge_instances[count.index].service_ip]
  source_dest_check = false
  description       = "service"

  tags = {
    Name = "${local.config.name}-interface-service-${count.index}"
  }
}


# PUBLIC IP

resource "aws_eip" "c8000v_eip" {
  count                     = length(local.config.edge_instances)
  domain                    = "vpc"
  network_interface         = aws_network_interface.network_transport[count.index].id
  associate_with_private_ip = tolist(aws_network_interface.network_transport[count.index].private_ips)[0]
  depends_on                = [aws_instance.c8000v]
  tags = {
    Name = "${local.config.name}-eip-${count.index}"
  }
}
