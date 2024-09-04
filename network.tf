
# SUBNETS

resource "aws_subnet" "transport" {
  vpc_id            = aws_vpc.instance.id
  cidr_block        = local.config.cloud.subnet_transport_prefix
  availability_zone = local.config.cloud.availability_zone

  tags = {
    Name = "${local.config.name}-subnet-transport"
  }
}

resource "aws_subnet" "service" {
  vpc_id            = aws_vpc.instance.id
  cidr_block        = local.config.cloud.subnet_service_prefix
  availability_zone = local.config.cloud.availability_zone

  tags = {
    Name = "${local.config.name}-subnet-service"
  }
}

# GATEWAY

resource "aws_internet_gateway" "instance" {
  vpc_id = aws_vpc.instance.id

  tags = {
    Name = "${local.config.name}-igw"
  }
}

# ROUTE TABLE

resource "aws_route_table" "network_transport" {
  vpc_id = aws_vpc.instance.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.instance.id
  }

  tags = {
    Name = "${local.config.name}-transport"
  }
}

#  ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "network_transport" {
  subnet_id      = aws_subnet.transport.id
  route_table_id = aws_route_table.network_transport.id
}

# INTERFACES

resource "aws_network_interface" "network_transport" {
  subnet_id         = aws_subnet.transport.id
  security_groups   = [aws_security_group.transport.id]
  private_ips       = [local.config.cloud.transport_ip]
  source_dest_check = false
  description       = "transport"

  tags = {
    Name = "${local.config.name}-interface-transport"
  }
}

resource "aws_network_interface" "network_service" {
  subnet_id         = aws_subnet.service.id
  security_groups   = [aws_security_group.transport.id]
  private_ips       = [local.config.cloud.service_ip]
  source_dest_check = false
  description       = "service"

  tags = {
    Name = "${local.config.name}-interface-service"
  }
}
