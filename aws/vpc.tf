
# VPC

resource "aws_vpc" "instance" {
  cidr_block           = local.config.aws.address_space
  enable_dns_hostnames = true

  tags = {
    Name = "${local.config.name}-vpc"
  }
}
