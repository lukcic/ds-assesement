module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vpc_cidr
  networks = [
    {
      name     = "eun1-az1"
      new_bits = 8
    },
    {
      name     = "eun1-az2"
      new_bits = 8
    },
    {
      name     = "eun1-az3"
      new_bits = 8
    }
  ]
}

resource "aws_vpc" "elasticsearch_vpc" {
  cidr_block = module.subnet_addrs.base_cidr_block
  tags = {
    Name = "${var.project_name}-${var.project_env}-vpc"
  }
}

resource "aws_subnet" "elasticsearch_subnet" {
  for_each = module.subnet_addrs.network_cidr_blocks

  vpc_id            = aws_vpc.elasticsearch_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  depends_on = [aws_vpc.elasticsearch_vpc]

  tags = {
    Name = "${var.project_name}-${var.project_env}-subnet-${each.key}"
  }
}

resource "aws_eip" "elasticsearch_eip" {
  tags = {
    Name = "${var.project_name}-${var.project_env}-nat_gateway_eip"
  }
}

output "elasticsearch_eip" {
  value = aws_eip.elasticsearch_eip.public_ip
}

resource "aws_nat_gateway" "elasticsearch_nat_gateway" {
  connectivity_type = "public"
  allocation_id     = aws_eip.elasticsearch_eip.id
  subnet_id         = aws_subnet.elasticsearch_subnet["eun1-az1"].id
  depends_on        = [aws_subnet.elasticsearch_subnet, aws_eip.elasticsearch_eip]

  tags = {
    Name = "${var.project_name}-${var.project_env}-nat_gateway"
  }
}

resource "aws_route_table" "elasticsearch_route_table" {
  for_each = module.subnet_addrs.network_cidr_blocks

  vpc_id     = aws_vpc.elasticsearch_vpc.id
  depends_on = [aws_nat_gateway.elasticsearch_nat_gateway]

  route {
    cidr_block = module.subnet_addrs.base_cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/24"
    nat_gateway_id = aws_nat_gateway.elasticsearch_nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-nat-route-table"
  }
}

